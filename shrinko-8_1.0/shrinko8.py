#!/usr/bin/env python3
from utils import *
from pico_process import PicoContext, process_code, CartSource, CustomPreprocessor
from pico_compress import write_code_size, write_compressed_size
from pico_cart import CartFormat, read_cart, write_cart, download_cart_from_bbs
import argparse, importlib.util

def CommaSep(val):
    return val.split(",")

def CartFormatFromStr(val):
    return CartFormat(val.replace("-", "_").replace(" ", "_"))

def CartFormatList(list):
    return ",".join(str.replace("_", "-") for str in list)

extend_arg = "extend" if sys.version_info >= (3,8) else None

parser = argparse.ArgumentParser()
parser.add_argument("input", help="input file, can be in any format. ('-' for stdin)")
parser.add_argument("output", help="output file. ('-' for stdout)", nargs='?')

parser.add_argument("-f", "--format", type=CartFormatFromStr, help="output format {%s}" % CartFormatList(CartFormat._output_names))
parser.add_argument("-F", "--input-format", type=CartFormatFromStr, help="input format {%s}" % CartFormatList(CartFormat._input_names))
parser.add_argument("-u", "--unicode-caps", action="store_true", help="write capitals as italicized unicode characters (better for copy/paste)")

pgroup = parser.add_argument_group("minify options")
pgroup.add_argument("-m", "--minify", action="store_true", help="enable minification")
pgroup.add_argument("-p", "--preserve", type=CommaSep, action=extend_arg, help='preserve specific identifiers in minification, e.g. "global1,global2,*.member2,table3.*"')
pgroup.add_argument("--no-preserve", type=CommaSep, action=extend_arg, help='do not preserve specific built-in identifiers in minification, e.g. "circfill,rectfill"')
pgroup.add_argument("--no-minify-rename", action="store_true", help="disable variable renaming in minification")
pgroup.add_argument("--no-minify-spaces", action="store_true", help="disable space removal in minification")
pgroup.add_argument("--no-minify-lines", action="store_true", help="disable line removal in minification")
pgroup.add_argument("--no-minify-comments", action="store_true", help="disable comment removal in minification (requires --no-minify-spaces)")
pgroup.add_argument("--no-minify-tokens", action="store_true", help="disable token removal in minification")
pgroup.add_argument("--rename-members-as-globals", action="store_true", help="rename globals and members the same way")
pgroup.add_argument("--rename-map", help="log renaming of identifiers (from minify step) to this file")

pgroup = parser.add_argument_group("lint options")
pgroup.add_argument("-l", "--lint", action="store_true", help="enable erroring on lint errors")
pgroup.add_argument("--no-lint-unused", action="store_true", help="don't print lint errors on unused variables")
pgroup.add_argument("--no-lint-duplicate", action="store_true", help="don't print lint errors on duplicate variables")
pgroup.add_argument("--no-lint-undefined", action="store_true", help="don't print lint errors on undefined variables")
pgroup.add_argument("--no-lint-fail", action="store_true", help="don't fail immediately on lint errors")

pgroup = parser.add_argument_group("count options")
pgroup.add_argument("-c", "--count", action="store_true", help="enable printing token count, character count & compressed size")
pgroup.add_argument("--input-count", action="store_true", help="enable printing input token count, character count & compressed size")

pgroup = parser.add_argument_group("script options")
pgroup.add_argument("-s", "--script", help="manipulate the cart via a custom python script - see README for api details")
pgroup.add_argument("--script-args", nargs=argparse.REMAINDER, help="send arguments directly to --script", default=())

pgroup = parser.add_argument_group("misc. options (semi-undocumented)")
pgroup.add_argument("--builtin", type=CommaSep, action=extend_arg, help="treat identifier as a pico-8 builtin (for minify, lint, etc.)")
pgroup.add_argument("--version", action="store_true", help="print version of cart")
pgroup.add_argument("--bbs", action="store_true", help="interpret input file as a bbs cart id, e.g. '#...'")
pgroup.add_argument("--fast-compression", action="store_true", help="force fast but poor compression (when creating pngs)")
pgroup.add_argument("--force-compression", action="store_true", help="force code compression even if code fits (when creating pngs)")
pgroup.add_argument("--custom-preprocessor", action="store_true", help="enable a custom preprocessor (#define X 123, #ifdef X, #[X], #[X[[print('X enabled')]]])")

if len(sys.argv) <= 1: # help is better than usage
    parser.print_help(sys.stderr)
    sys.exit(1)

args = parser.parse_args()

if args.input == "-":
    args.input = StdPath("-")
if args.output == "-":
    args.output = StdPath("-")

if args.bbs:
    args.input = DataPath(args.input, download_cart_from_bbs(args.input))
    args.input_format = CartFormat.png

def fail(msg):
    eprint(msg)
    sys.exit(1)

if not args.lint and not args.count and not args.output and not args.input_count and not args.version:
    fail("No operation (--lint/--count) or output file specified")
if args.format and not args.output:
    fail("Output should be specified under --format")
if args.minify and not args.output and not args.count:
    fail("Output (or --count) should be specified under --minify")
    
if not args.format and args.output:
    ext = path_extension(args.output)[1:].lower()
    if ext in CartFormat._ext_names:
        args.format = CartFormat(ext)
    else:
        args.format = CartFormat.p8

if not args.input_format and args.input:
    ext = path_extension(args.input)[1:].lower()
    if ext in CartFormat._ext_names:
        args.input_format = CartFormat(ext)

if args.lint:
    args.lint = {
        "unused": not args.no_lint_unused,
        "duplicate": not args.no_lint_duplicate,
        "undefined": not args.no_lint_undefined,
    }

if args.minify:
    args.minify = {
        "lines": not args.no_minify_lines,
        "wspace": not args.no_minify_spaces,
        "comments": not args.no_minify_comments,
        "tokens": not args.no_minify_tokens,
    }

args.obfuscate = bool(args.minify) and not args.no_minify_rename
if args.obfuscate:
    args.obfuscate = {
        "members=globals": args.rename_members_as_globals,
    }
    if args.preserve or args.no_preserve:
        rules = {}
        if args.preserve:
            rules.update({k: False for k in args.preserve})
        if args.no_preserve:
            rules.update({k: True for k in args.no_preserve})
        args.obfuscate["rules"] = rules

preproc_cb, postproc_cb, sublang_cb = None, None, None
if args.script:
    script_spec = importlib.util.spec_from_file_location(path_basename_no_extension(args.script), args.script)
    script_mod = importlib.util.module_from_spec(script_spec)
    script_spec.loader.exec_module(script_mod)
    preproc_cb = getattr(script_mod, "preprocess_main", None)
    postproc_cb = getattr(script_mod, "postprocess_main", None)
    sublang_cb = getattr(script_mod, "sublanguage_main", None)

preprocessor = CustomPreprocessor() if args.custom_preprocessor else None
cart = read_cart(args.input, args.input_format, print_sizes=args.input_count, preprocessor=preprocessor)
src = CartSource(cart)

if args.input_count:
    write_code_size(cart, input=True)
    
ctxt = PicoContext(extra_globals=args.builtin, srcmap=args.rename_map, sublang_getter=sublang_cb)
if preproc_cb:
    preproc_cb(cart=cart, src=src, ctxt=ctxt, args=args, res_path=None) # (res_path is obsolete)

ok, errors = process_code(ctxt, src, input_count=args.input_count, count=args.count,
                          lint=args.lint, minify=args.minify, obfuscate=args.obfuscate, fail=False)
if errors:
    print("Lint errors:" if ok else "Compilation errors:")
    for error in errors:
        print(error)
    if not ok or not args.no_lint_fail:
        sys.exit(1)

if args.rename_map:
    file_write_text(args.rename_map, "\n".join(ctxt.srcmap))
    
if postproc_cb:
    postproc_cb(cart=cart, args=args, res_path=None) # (res_path is obsolete)

if args.count:
    write_code_size(cart)
    if not (args.output and str(args.format) not in CartFormat._src_names): # else, will be done in write_cart
        write_compressed_size(cart, fast_compress=args.fast_compression)

if args.output:
    write_cart(args.output, cart, args.format, print_sizes=args.count, 
               unicode_caps=args.unicode_caps,
               force_compress=args.count or args.force_compression,
               fast_compress=args.fast_compression)

if args.version:
    print("version: %d, v%d.%d.%d:%d, %c" % (cart.version_id, *cart.version_tuple, cart.platform))

if errors:
    sys.exit(2)
