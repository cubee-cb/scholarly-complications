import os
import re

 
def preprocess_main(cart, args, **_):

    print("removing code sections marked as debug...")
    #https://stackoverflow.com/a/40782646 SCENARIO 2
    cart.code = re.sub(r'--db([\s\S]*?)--dbe', '', cart.code, flags=re.MULTILINE)

    #print(cart.code)


def postprocess_main(cart, **_):

    print("removing # commented lines from strings...")
    #https://stackoverflow.com/a/32256589
    cart.code = re.sub(r'^#.*\n?', '', cart.code, flags=re.MULTILINE)

    print("removing empty lines from strings...")
    #https://stackoverflow.com/a/1140966
    cart.code = os.linesep.join([s for s in cart.code.splitlines() if s])

    #print(cart.code)