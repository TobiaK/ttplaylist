# ttplaylist
Create a playlist of mp3 file collections into the TipToi pen format.

Convert any folder with mp3s to a gme file.


Usage: ttplaylist -n name -i productId [-h] -t tttoolsPath -m mp3Path

tttool mp3 playlist creater -v0.1

## Available options

  -m Get all mp3 files from this path

  -i Use this product id
  
  -n Name of the created playlist
  
  -t Path of tttools
  
  -h Show this help text
  
## Example

### Comand
'/home/tobiak/workspace/ttplaylist/ttplaylist.sh' -n exampleProject -i 42 -t '/home/tobiak/tttool/'
-m '/home/tobiak/Musik/Kinder/Rotz '\''n'\'' Roll Radio/Partypiepel' 

### Result

  - oid-42.png
  - exampleProject.gme
  - exampleProject.yaml

### Create pdf
tttool oid-table ./exampleProject.gme

### Test gme
tttool play ./exampleProject.gme

## Used OIDs

- 8000: Start playing list

- 8001: Switsch to info mode

- 8002: Skip to next track

- 8003: Skip to previous track

  

- 9001: Play track 1

- 9002: Play track 2

...

- 9065: Play trak 65

## Play musik on TipToi pen
- copy gme file on pen

- scan created oid-X.png image

- scan OID

## TODOs
- [ ] Image for player controls

- [ ] Image for tracks 1 - n
