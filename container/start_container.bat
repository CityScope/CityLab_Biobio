@echo off

set "ruta_host1=C:\Users\CityLab Biobio - DS\Dev\ds_ccp\data"
set "ruta_contenedor1=/app/data"

set "nombre_imagen=urban_indicators"
set "nombre_contenedor=ui_clbb"

docker run -d -p 8888:8888 ^
  -v "%ruta_host1%:%ruta_contenedor1%" ^
  -e JUPYTER_TOKEN="" ^
  --name "%nombre_contenedor%" ^
  "%nombre_imagen%"