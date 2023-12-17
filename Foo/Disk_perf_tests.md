# Disk Performance Tests
I was a bit curious how my SATA-SSD would perform vs my NVMe SSD.

For this rudimentary test, I looked at:

* /mnt/openebs which is an LVM sitting on my SATA disk
* /var/openebs on the NVMe "OS disk"


## Read Test
### SSD (SATA) performance
```
root@eks-host01:/mnt/openebs# fio --name READTEST --eta-newline=5s --filename=fio-tempfile.dat --rw=read --size=500m --io_size=10g --blocksize=1024k --ioengine=libaio --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting
TEST: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
fio-3.28
Starting 1 process
READTEST: Laying out IO file (1 file / 500MiB)
Jobs: 1 (f=1): [R(1)][30.4%][r=508MiB/s][r=508 IOPS][eta 00m:16s]
Jobs: 1 (f=1): [R(1)][57.1%][r=511MiB/s][r=511 IOPS][eta 00m:09s]
Jobs: 1 (f=1): [R(1)][81.0%][r=511MiB/s][r=511 IOPS][eta 00m:04s]
Jobs: 1 (f=1): [R(1)][100.0%][r=490MiB/s][r=489 IOPS][eta 00m:00s]
READTEST: (groupid=0, jobs=1): err= 0: pid=3255750: Sun Dec 17 18:35:53 2023
  read: IOPS=510, BW=511MiB/s (536MB/s)(10.0GiB/20048msec)
    slat (usec): min=16, max=831, avg=113.23, stdev=68.86
    clat (msec): min=2, max=128, avg=62.29, stdev=12.45
     lat (msec): min=2, max=128, avg=62.41, stdev=12.45
    clat percentiles (msec):
     |  1.00th=[   11],  5.00th=[   48], 10.00th=[   62], 20.00th=[   62],
     | 30.00th=[   63], 40.00th=[   63], 50.00th=[   63], 60.00th=[   63],
     | 70.00th=[   63], 80.00th=[   64], 90.00th=[   64], 95.00th=[   74],
     | 99.00th=[  114], 99.50th=[  118], 99.90th=[  123], 99.95th=[  123],
     | 99.99th=[  127]
   bw (  KiB/s): min=491520, max=526336, per=99.92%, avg=522596.00, stdev=5677.39, samples=40
   iops        : min=  480, max=  514, avg=510.25, stdev= 5.53, samples=40
  lat (msec)   : 4=0.12%, 10=0.68%, 20=1.14%, 50=3.31%, 100=92.47%
  lat (msec)   : 250=2.28%
  cpu          : usr=0.90%, sys=6.81%, ctx=10227, majf=0, minf=8204
  IO depths    : 1=0.2%, 2=0.4%, 4=0.8%, 8=1.6%, 16=3.3%, 32=93.6%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=99.8%, 8=0.0%, 16=0.0%, 32=0.2%, 64=0.0%, >=64=0.0%
     issued rwts: total=10240,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=511MiB/s (536MB/s), 511MiB/s-511MiB/s (536MB/s-536MB/s), io=10.0GiB (10.7GB), run=20048-20048msec

Disk stats (read/write):
    dm-0: ios=10149/18, merge=0/0, ticks=610580/672, in_queue=611252, util=99.67%, aggrios=17701/15, aggrmerge=0/3, aggrticks=1061128/559, aggrin_queue=1061761, aggrutil=99.25%
  sda: ios=17701/15, merge=0/3, ticks=1061128/559, in_queue=1061761, util=99.25%
```

### NVMe performance
```
root@eks-host01:/var/openebs# fio --name READTEST --eta-newline=5s --filename=fio-tempfile.dat --rw=read --size=500m --io_size=10g --blocksize=1024k --ioengine=libaio --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting
READTEST: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
fio-3.28
Starting 1 process
READTEST: Laying out IO file (1 file / 500MiB)
Jobs: 1 (f=1): [R(1)][100.0%][r=3295MiB/s][r=3295 IOPS][eta 00m:00s]
READTEST: (groupid=0, jobs=1): err= 0: pid=3266915: Sun Dec 17 18:43:35 2023
  read: IOPS=3297, BW=3298MiB/s (3458MB/s)(10.0GiB/3105msec)
    slat (usec): min=14, max=220, avg=19.81, stdev=11.02
    clat (usec): min=555, max=18531, avg=9633.86, stdev=1751.32
     lat (usec): min=574, max=18548, avg=9653.74, stdev=1749.51
    clat percentiles (usec):
     |  1.00th=[ 2409],  5.00th=[ 7832], 10.00th=[ 8717], 20.00th=[ 9110],
     | 30.00th=[ 9241], 40.00th=[ 9503], 50.00th=[ 9634], 60.00th=[ 9765],
     | 70.00th=[10028], 80.00th=[10290], 90.00th=[10683], 95.00th=[11600],
     | 99.00th=[15926], 99.50th=[16712], 99.90th=[17695], 99.95th=[17957],
     | 99.99th=[18482]
   bw (  MiB/s): min= 3282, max= 3326, per=100.00%, avg=3301.33, stdev=16.62, samples=6
   iops        : min= 3282, max= 3326, avg=3301.33, stdev=16.62, samples=6
  lat (usec)   : 750=0.17%, 1000=0.10%
  lat (msec)   : 2=0.52%, 4=1.22%, 10=67.32%, 20=30.67%
  cpu          : usr=1.19%, sys=8.05%, ctx=10161, majf=0, minf=8202
  IO depths    : 1=0.2%, 2=0.4%, 4=0.8%, 8=1.6%, 16=3.3%, 32=93.6%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=99.8%, 8=0.0%, 16=0.0%, 32=0.2%, 64=0.0%, >=64=0.0%
     issued rwts: total=10240,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=3298MiB/s (3458MB/s), 3298MiB/s-3298MiB/s (3458MB/s-3458MB/s), io=10.0GiB (10.7GB), run=3105-3105msec

Disk stats (read/write):
  nvme0n1: ios=22583/102, merge=0/21, ticks=205540/88, in_queue=205694, util=97.28%
```




## Mixed random 4K read and write QD1 with sync

### SATA Performance
```
cd /mnt/openebs
 fio --name RANDOMTEST --eta-newline=5s --filename=fio-tempfile.dat --rw=randrw --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting

root@eks-host01:/var/openebs# cd /mnt/openebs
 fio --name RANDOMTEST --eta-newline=5s --filename=fio-tempfile.dat --rw=randrw --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
RANDOMTEST: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=1
fio-3.28
Starting 1 process
Jobs: 1 (f=1): [m(1)][11.7%][r=5312KiB/s,w=5144KiB/s][r=1328,w=1286 IOPS][eta 00m:53s]
Jobs: 1 (f=1): [m(1)][21.7%][r=5044KiB/s,w=5128KiB/s][r=1261,w=1282 IOPS][eta 00m:47s]
Jobs: 1 (f=1): [m(1)][31.7%][r=4920KiB/s,w=5045KiB/s][r=1230,w=1261 IOPS][eta 00m:41s]
Jobs: 1 (f=1): [m(1)][41.7%][r=4832KiB/s,w=4872KiB/s][r=1208,w=1218 IOPS][eta 00m:35s]
Jobs: 1 (f=1): [m(1)][51.7%][r=5088KiB/s,w=4760KiB/s][r=1272,w=1190 IOPS][eta 00m:29s]
Jobs: 1 (f=1): [m(1)][61.7%][r=5176KiB/s,w=4936KiB/s][r=1294,w=1234 IOPS][eta 00m:23s]
Jobs: 1 (f=1): [m(1)][71.7%][r=4984KiB/s,w=5008KiB/s][r=1246,w=1252 IOPS][eta 00m:17s]
Jobs: 1 (f=1): [m(1)][81.7%][r=5284KiB/s,w=4864KiB/s][r=1321,w=1216 IOPS][eta 00m:11s]
Jobs: 1 (f=1): [m(1)][91.7%][r=5245KiB/s,w=4940KiB/s][r=1311,w=1235 IOPS][eta 00m:05s]
Jobs: 1 (f=1): [m(1)][100.0%][r=5100KiB/s,w=4916KiB/s][r=1275,w=1229 IOPS][eta 00m:00s]
RANDOMTEST: (groupid=0, jobs=1): err= 0: pid=3277850: Sun Dec 17 18:52:25 2023
  read: IOPS=1260, BW=5042KiB/s (5163kB/s)(295MiB/60001msec)
    slat (usec): min=2, max=143, avg= 5.85, stdev= 6.42
    clat (nsec): min=565, max=1204.1k, avg=160220.33, stdev=15166.81
     lat (usec): min=94, max=1215, avg=166.17, stdev=17.58
    clat percentiles (usec):
     |  1.00th=[  122],  5.00th=[  124], 10.00th=[  159], 20.00th=[  161],
     | 30.00th=[  161], 40.00th=[  161], 50.00th=[  163], 60.00th=[  163],
     | 70.00th=[  163], 80.00th=[  165], 90.00th=[  165], 95.00th=[  167],
     | 99.00th=[  202], 99.50th=[  206], 99.90th=[  289], 99.95th=[  314],
     | 99.99th=[  383]
   bw (  KiB/s): min= 4488, max= 5728, per=100.00%, avg=5047.26, stdev=247.83, samples=119
   iops        : min= 1122, max= 1432, avg=1261.82, stdev=61.96, samples=119
  write: IOPS=1254, BW=5018KiB/s (5138kB/s)(294MiB/60001msec); 0 zone resets
    slat (usec): min=3, max=346, avg= 6.11, stdev= 6.46
    clat (usec): min=14, max=2699, avg=26.96, stdev=27.93
     lat (usec): min=25, max=2711, avg=33.17, stdev=29.54
    clat percentiles (usec):
     |  1.00th=[   23],  5.00th=[   24], 10.00th=[   24], 20.00th=[   24],
     | 30.00th=[   24], 40.00th=[   24], 50.00th=[   25], 60.00th=[   26],
     | 70.00th=[   26], 80.00th=[   26], 90.00th=[   29], 95.00th=[   30],
     | 99.00th=[   70], 99.50th=[   83], 99.90th=[  235], 99.95th=[  375],
     | 99.99th=[ 1532]
   bw (  KiB/s): min= 4376, max= 5720, per=100.00%, avg=5022.39, stdev=208.04, samples=119
   iops        : min= 1094, max= 1430, avg=1255.60, stdev=52.01, samples=119
  lat (nsec)   : 750=0.01%
  lat (usec)   : 20=0.01%, 50=48.59%, 100=1.13%, 250=50.15%, 500=0.10%
  lat (usec)   : 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=0.01%
  fsync/fdatasync/sync_file_range:
    sync (nsec): min=37, max=40119, avg=316.16, stdev=1698.65
    sync percentiles (nsec):
     |  1.00th=[   49],  5.00th=[   57], 10.00th=[   62], 20.00th=[   71],
     | 30.00th=[   77], 40.00th=[   82], 50.00th=[   90], 60.00th=[   99],
     | 70.00th=[  111], 80.00th=[  139], 90.00th=[  708], 95.00th=[  868],
     | 99.00th=[ 1112], 99.50th=[21376], 99.90th=[22400], 99.95th=[22656],
     | 99.99th=[24192]
  cpu          : usr=1.92%, sys=2.92%, ctx=422896, majf=0, minf=17
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=75629,75265,0,150891 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=5042KiB/s (5163kB/s), 5042KiB/s-5042KiB/s (5163kB/s-5163kB/s), io=295MiB (310MB), run=60001-60001msec
  WRITE: bw=5018KiB/s (5138kB/s), 5018KiB/s-5018KiB/s (5138kB/s-5138kB/s), io=294MiB (308MB), run=60001-60001msec

Disk stats (read/write):
    dm-0: ios=75524/313600, merge=0/0, ticks=17188/38020, in_queue=55208, util=99.88%, aggrios=75629/284808, aggrmerge=0/29320, aggrticks=12067/43358, aggrin_queue=94536, aggrutil=99.77%
  sda: ios=75629/284808, merge=0/29320, ticks=12067/43358, in_queue=94536, util=99.77%
```

### NVMe Performance
```
cd /var/openebs
fio --name RANDOMTEST --eta-newline=5s --filename=fio-tempfile.dat --rw=randrw --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
RANDOMTEST: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=1
fio-3.28
Starting 1 process
Jobs: 1 (f=1): [m(1)][11.7%][r=492KiB/s,w=436KiB/s][r=123,w=109 IOPS][eta 00m:53s]
Jobs: 1 (f=1): [m(1)][21.7%][r=412KiB/s,w=484KiB/s][r=103,w=121 IOPS][eta 00m:47s]
Jobs: 1 (f=1): [m(1)][31.7%][r=284KiB/s,w=348KiB/s][r=71,w=87 IOPS][eta 00m:41s]
Jobs: 1 (f=1): [m(1)][41.7%][r=416KiB/s,w=456KiB/s][r=104,w=114 IOPS][eta 00m:35s]
Jobs: 1 (f=1): [m(1)][51.7%][r=488KiB/s,w=468KiB/s][r=122,w=117 IOPS][eta 00m:29s]
Jobs: 1 (f=1): [m(1)][61.7%][r=360KiB/s,w=332KiB/s][r=90,w=83 IOPS][eta 00m:23s]
Jobs: 1 (f=1): [m(1)][71.7%][r=488KiB/s,w=456KiB/s][r=122,w=114 IOPS][eta 00m:17s]
Jobs: 1 (f=1): [m(1)][81.7%][r=484KiB/s,w=408KiB/s][r=121,w=102 IOPS][eta 00m:11s]
Jobs: 1 (f=1): [m(1)][91.7%][r=436KiB/s,w=448KiB/s][r=109,w=112 IOPS][eta 00m:05s]
Jobs: 1 (f=1): [m(1)][100.0%][r=440KiB/s,w=456KiB/s][r=110,w=114 IOPS][eta 00m:00s]
RANDOMTEST: (groupid=0, jobs=1): err= 0: pid=3275739: Sun Dec 17 18:51:00 2023
  read: IOPS=109, BW=439KiB/s (449kB/s)(25.7MiB/60003msec)
    slat (usec): min=2, max=189, avg=42.02, stdev=30.12
    clat (nsec): min=1464, max=8027.0k, avg=86748.00, stdev=103295.80
     lat (usec): min=42, max=8046, avg=129.70, stdev=107.44
    clat percentiles (usec):
     |  1.00th=[   40],  5.00th=[   44], 10.00th=[   51], 20.00th=[   56],
     | 30.00th=[   65], 40.00th=[   76], 50.00th=[   83], 60.00th=[   88],
     | 70.00th=[   93], 80.00th=[  106], 90.00th=[  141], 95.00th=[  157],
     | 99.00th=[  174], 99.50th=[  178], 99.90th=[  190], 99.95th=[  196],
     | 99.99th=[ 8029]
   bw (  KiB/s): min=  272, max=  648, per=99.84%, avg=438.99, stdev=71.61, samples=119
   iops        : min=   68, max=  162, avg=109.75, stdev=17.90, samples=119
  write: IOPS=110, BW=441KiB/s (451kB/s)(25.8MiB/60003msec); 0 zone resets
    slat (usec): min=4, max=203, avg=50.73, stdev=33.15
    clat (nsec): min=1871, max=161901, avg=48223.87, stdev=20916.69
     lat (usec): min=18, max=271, avg=99.91, stdev=50.92
    clat percentiles (usec):
     |  1.00th=[   15],  5.00th=[   17], 10.00th=[   19], 20.00th=[   24],
     | 30.00th=[   31], 40.00th=[   47], 50.00th=[   54], 60.00th=[   59],
     | 70.00th=[   63], 80.00th=[   68], 90.00th=[   72], 95.00th=[   75],
     | 99.00th=[   92], 99.50th=[  109], 99.90th=[  133], 99.95th=[  143],
     | 99.99th=[  163]
   bw (  KiB/s): min=  280, max=  512, per=100.00%, avg=441.21, stdev=35.53, samples=119
   iops        : min=   70, max=  128, avg=110.30, stdev= 8.88, samples=119
  lat (usec)   : 2=0.02%, 10=0.12%, 20=7.00%, 50=19.19%, 100=61.83%
  lat (usec)   : 250=11.83%, 500=0.01%
  lat (msec)   : 10=0.01%
  fsync/fdatasync/sync_file_range:
    sync (nsec): min=64, max=42215, avg=1131.34, stdev=1254.96
    sync percentiles (nsec):
     |  1.00th=[  117],  5.00th=[  171], 10.00th=[  187], 20.00th=[  223],
     | 30.00th=[  652], 40.00th=[  924], 50.00th=[ 1012], 60.00th=[ 1160],
     | 70.00th=[ 1448], 80.00th=[ 1912], 90.00th=[ 2128], 95.00th=[ 2288],
     | 99.00th=[ 2544], 99.50th=[ 2672], 99.90th=[22144], 99.95th=[22912],
     | 99.99th=[34048]
  cpu          : usr=0.56%, sys=1.92%, ctx=29632, majf=0, minf=18
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=6581,6611,0,13189 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=439KiB/s (449kB/s), 439KiB/s-439KiB/s (449kB/s-449kB/s), io=25.7MiB (27.0MB), run=60003-60003msec
  WRITE: bw=441KiB/s (451kB/s), 441KiB/s-441KiB/s (451kB/s-451kB/s), io=25.8MiB (27.1MB), run=60003-60003msec

Disk stats (read/write):
  nvme0n1: ios=6587/31792, merge=0/12051, ticks=575/58526, in_queue=76437, util=99.86%
```

## SATA Performance
```
root@eks-host01:/mnt/openebs# fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.28
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [m(1)][100.0%][r=72.8MiB/s,w=24.0MiB/s][r=18.6k,w=6138 IOPS][eta 00m:00s]
test: (groupid=0, jobs=1): err= 0: pid=3610936: Sun Dec 17 22:51:05 2023
  read: IOPS=19.1k, BW=74.4MiB/s (78.1MB/s)(3070MiB/41243msec)
   bw (  KiB/s): min=64712, max=82584, per=99.95%, avg=76187.22, stdev=6331.41, samples=82
   iops        : min=16178, max=20646, avg=19046.80, stdev=1582.85, samples=82
  write: IOPS=6368, BW=24.9MiB/s (26.1MB/s)(1026MiB/41243msec); 0 zone resets
   bw (  KiB/s): min=21168, max=27904, per=99.94%, avg=25459.80, stdev=2146.88, samples=82
   iops        : min= 5292, max= 6976, avg=6364.95, stdev=536.72, samples=82
  cpu          : usr=3.08%, sys=11.74%, ctx=978392, majf=0, minf=8
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=74.4MiB/s (78.1MB/s), 74.4MiB/s-74.4MiB/s (78.1MB/s-78.1MB/s), io=3070MiB (3219MB), run=41243-41243msec
  WRITE: bw=24.9MiB/s (26.1MB/s), 24.9MiB/s-24.9MiB/s (26.1MB/s-26.1MB/s), io=1026MiB (1076MB), run=41243-41243msec

Disk stats (read/write):
    dm-0: ios=782177/261472, merge=0/0, ticks=2030276/588212, in_queue=2618488, util=99.82%, aggrios=784364/262517, aggrmerge=1556/214, aggrticks=2032950/591862, aggrin_queue=2624832, aggrutil=99.66%
  sda: ios=784364/262517, merge=1556/214, ticks=2032950/591862, in_queue=2624832, util=99.66%
```

### NVMe Performance
```
root@eks-host01:/var/openebs# fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.28
Starting 1 process
Jobs: 1 (f=1): [m(1)][-.-%][r=932MiB/s,w=311MiB/s][r=239k,w=79.6k IOPS][eta 00m:00s]
test: (groupid=0, jobs=1): err= 0: pid=3613999: Sun Dec 17 22:52:38 2023
  read: IOPS=237k, BW=924MiB/s (969MB/s)(3070MiB/3321msec)
   bw (  KiB/s): min=927216, max=958584, per=100.00%, avg=947045.33, stdev=11368.16, samples=6
   iops        : min=231804, max=239646, avg=236761.33, stdev=2842.04, samples=6
  write: IOPS=79.1k, BW=309MiB/s (324MB/s)(1026MiB/3321msec); 0 zone resets
   bw (  KiB/s): min=308896, max=321960, per=100.00%, avg=316841.33, stdev=4907.46, samples=6
   iops        : min=77224, max=80490, avg=79210.33, stdev=1226.86, samples=6
  cpu          : usr=18.19%, sys=67.02%, ctx=244661, majf=0, minf=8
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=924MiB/s (969MB/s), 924MiB/s-924MiB/s (969MB/s-969MB/s), io=3070MiB (3219MB), run=3321-3321msec
  WRITE: bw=309MiB/s (324MB/s), 309MiB/s-309MiB/s (324MB/s-324MB/s), io=1026MiB (1076MB), run=3321-3321msec

Disk stats (read/write):
  nvme0n1: ios=743608/248859, merge=0/31, ticks=43051/2897, in_queue=46011, util=97.07%
```
