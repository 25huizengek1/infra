{
  writers,
  python313Packages,
  python313,
}:

let
  writer = writers.makePythonWriter python313 python313Packages python313Packages;
  script = ''
    import asyncio
    from bleak import BleakScanner


    async def scan():
        devices = await BleakScanner.discover(5.0)
        for d in devices:
            if 'MeshCore' in (d.name or ""):
                print(f'{d.address}  {d.name}')


    print('Starting scan...')
    asyncio.run(scan())
  '';
in
writer "/bin/meshcore-scan" {
  libraries = with python313Packages; [
    bleak
  ];
} script
