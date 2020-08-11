```
git clone <this repository>
docker build -t m3u8converter .
docker run -v "$(pwd):/tmp/workdir" -it --rm m3u8converter -i <m3u8 file> -b <base url>
```
