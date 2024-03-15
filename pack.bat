@echo off
cd "%~dp0"
python "shrinko-8\shrinko8.py" "beatem.p8" "beatem-packed.p8"^
 --minify^
 --count^
 --no-minify-rename^
 --script process.py^
 --rename-map beatem-packed-redirects.txt

:: --preserve "*,*.*"^
:: --rename-members-as-globals^

::python "shrinko-8\shrinko8.py" "beatem.p8" "beatem-packed.p8" --minify  --count --script process.py
pause
::powershell -nop -c "& {sleep 3}"