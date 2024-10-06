# Local process with Julia

### Add Oracle Instant Client

#### In debian distributions run:

1. #### Install dependencies
```
sudo apt-get update
sudo apt-get install -y libaio1 libnsl-dev curl unzip gcc make
```

2. #### Download Oracle Instant Client
```
cd /tmp
curl -o instantclient-basiclite.zip https://download.oracle.com/otn_software/linux/instantclient/instantclient-basiclite-linuxx64.zip
curl -o instantclient-sdk.zip https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip
```
3. #### Unzip and move files

```
unzip -o instantclient-basiclite.zip
unzip -o instantclient-sdk.zip
sudo mv instantclient*/ /usr/lib/instantclient
rm instantclient-basiclite.zip instantclient-sdk.zip
```
4. #### Create symbolic links
```
sudo ln -s /usr/lib/instantclient/libclntsh.so.23.1 /usr/lib/libclntsh.so
sudo ln -s /usr/lib/instantclient/libocci.so.23.1 /usr/lib/libocci.so
sudo ln -s /usr/lib/instantclient/libociicus.so /usr/lib/libociicus.so
sudo ln -s /usr/lib/instantclient/libnnz19.so /usr/lib/libnnz19.so
sudo ln -s /usr/lib/instantclient/libnsl.so.2 /usr/lib/libnsl.so.1
sudo ln -s /lib/x86_64-linux-gnu/libc.so.6 /usr/lib/libresolv.so.2
sudo ln -s /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2
```
5. #### Set environment variables
```
nano ~/.bashrc
```

Add these lines to the end of the file.
```
export ORACLE_BASE=/usr/lib/instantclient
export LD_LIBRARY_PATH=/usr/lib/instantclient
export TNS_ADMIN=/usr/lib/instantclient
export ORACLE_HOME=/usr/lib/instantclient
```
Save and run
```
source ~/.bashrc
```

### Install Julia
1. Go to [Julia downloads](https://julialang.org/downloads/)



### Create julia project
```
julia> ] activate .
julia> ] instantiate
julia> ] status
```

### Modify ```.env``` file

### Set "julia.NumThreads": <your_nrs_of_thrs>
1. See it:
```
julia> versioninfo()
```
### Run .jl

1. To fetch data and only save with threads run:
```
julia fecthThreads.jl
```

2. To fetch data with async and only save with threads run:
```
julia asyncFetch.jl
```