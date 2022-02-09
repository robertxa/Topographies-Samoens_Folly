# therion-plotting-tools
Collection of data analysis and plotting tools for cave surveys created with Therion

## Usage
```
usage: plot.py [-h] [-s PATH] [-f {png,jpg,pdf,svg}] input {rose} ...

Create plots from a Therion sqlite database

positional arguments:
  input                 Input sqlite database exported by Therion
  {rose}                Available plots
    rose                Create a rose diagram

optional arguments:
  -h, --help            show this help message and exit
  -s PATH, --save PATH  Save the plots into the given directory
  -f {png,jpg,pdf,svg}, --format {png,jpg,pdf,svg}
                        File format of plots
```

```
usage: plot.py input rose [-h] [-b BINS]

optional arguments:
  -h, --help            show this help message and exit
  -b BINS, --bins BINS  Number of bins
```

```
usage: plot.py input shot-lengths [-h] [-b BINS] [-l]

optional arguments:
  -h, --help            show this help message and exit
  -b BINS, --bins BINS  Number of bins
  -l, --log             Use log scale
```
