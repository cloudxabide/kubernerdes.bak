# Hardware


| Cost | Qty | Total | Object       | Purpose                   | Link |
|:----:|:----|:------|:-------------|:--------------------------|:-----|
| 359  | 1   | 359   | Intel NUC    | Admin Host                | [Amazon - Intel NUC NUC10i7FNK1](https://www.amazon.com/gp/product/B083GGZ6TG/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&th=1) |
| 359  | 3   | 1077  | Intel NUC    | Kubernetes Host           | [Amazon - Intel NUC NUC10i7FNH](https://www.amazon.com/NUC10i7FNH-i7-10710U-Processor-Thunderbolt-Ethernet/dp/B0CNBGDXRM)  |
| 148  | 4   | 592   | Memory DIMM  | Host Memory               | [Corsair Vengeance Performance SODIMM Memory 64GB (2x32GB) DDR4 2933MHz CL19 Unbuffered for 8th Generation or Newer Intel Core™ i7, and AMD Ryzen 4000 Series Notebooks](https://www.amazon.com/gp/product/B08GSRD34Y/ref=ppx_od_dt_b_asin_title_s00?ie=UTF8&psc=1) | 
| 67   | 3   | 201   | 1TB SSD SATA | Host Storage (OS)         | [SanDisk Ultra 1TB SSD](https://www.amazon.com/SanDisk-Ultra-NAND-Internal-%E2%80%8ESDSSDH3-1T00-G26/dp/B0B7VM4SRX) | 
| 90   | 4   | 360   | 1TB SSD NVMe | Host Storage (containers | [SAMSUNG 970 EVO Plus SSD 1TB NVMe M.2 Internal Solid State Hard Drive, V-NAND Technology, Storage and Memory Expansion for Gaming, Graphics w/ Heat Control, Max Speed, MZ-V7S1T0B/AM](https://www.amazon.com/gp/product/B07MFZY2F2/ref=ppx_od_dt_b_asin_title_s00?ie=UTF8&th=1) |
|=====|=======|=======| | | 
|     | Totol | 2589  | | | 

| Cost | Qty | Total | Object      | Purpose | Link |
|:----:|:----|:------|:-------|:--------|:-----|
| | 4 | | Network Cables (3 ft) | |
| | 1 | | Power Strip | |
| | 1 | | Keyboard | |
| | 1 | | Mouse | |
| | 1 | | Monitor | |
| | 1 | | 4-port KVM Switch | |
| | 1 | | USB Stick (16GB) | Installing Ubuntu | |





Note:  The Intel NUC come in 2 form factors (possibly more).  There is the "slim/sleek" version and the "MiniPC" version? ( NUC10i7FNK1 vs NUC10i7FNH, perhaps?)

Intel NUC 10 Performance NUC10i7FNH Barebone System Mini PC

Hardware Configuration (Nutanix)

| Device    | Desc     | Qty | Purpose |
|:----------|:---------|:----|:--------|
| NUC       | Gen10 i7 | 1   | Admin Host |
| NUC       | Gen10 i7 | 3   | Worker Nodes |
| Switch    | 8-port   | 1   | Networking |
| USB NIC   | 1Gb      | 3   | Worker Node Networking |
| NVMe      | 1Tb      | 3   | CVM storage device |
| SSD       | 2Tb      | 3   | Data |
| USB drive | 64Gb     | 3   | Hypervisor | 
