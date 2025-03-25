# sdre-enthusiasts/docker-sdrmap

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [SDR Map's](http://sdrmap.org) feeder scripts. Designed to work in tandem with [sdr-enthusiasts/docker-adsb-ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder). Builds and runs on `x86_64`, `arm64`, and `arm32v7`.

## Obtaining credentials to feed

Please visit [feeding](https://github.com/sdrmap/docs/wiki/2.1-Feeding) for instructions on how to obtain credentials to feed. Once you have credentials, you can proceed with setting up the container.

## Up-and-Running with Docker Compose

```yaml
services:
  sdrmap:
    image: ghcr.io/sdr-enthusiasts/docker-sdrmap:latest
    container_name: sdrmap
    restart: always
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=readsb
      - READSB_LAT=-33.33333
      - READSB_LON=111.11111
      - SMUSERNAME=yourusername
      - SMPASSWORD=yourpassword
```

## MLAT

If you want to enable MLAT, you need to set the `MLAT` environment variable to `true`. You also need to set the `ALT` environment variable to the altitude of your antenna in meters. For example, if your antenna is 10 meters above sea level, you would set `ALT=10`. Both `MLAT` and `ALT` need to be set for MLAT to work.

You will want your instance of ultrafeeder to take in these results. Add in the following to the `ULTRAFEEDER_CONFIG` section of ultrafeeder

```yaml
mlathub,sdrmap,30105,beast_in;
```

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                                                                               | Default        |
| -------------------- | ------------------------------------------------------------------------------------- | -------------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090/readsb)                    |                |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090/readsy)                  | 30005          |
| `SMUSERNAME`         | Required. SDR Map                                                                     | `yourusername` |
| `SMPASSWORD`         | Required. SDR Map Password                                                            | `yourpassword` |
| `READSB_LAT`         | Required. Latitude of the antenna                                                     |                |
| `READSB_LON`         | Required. Longitude of the antenna                                                    |                |
| `ALT`                | For MLAT set the altitude in **_meters_**. No trailing `m` or other values necessary. | Unset          |
| `TZ`                 | Optional. Your local timezone                                                         | GMT            |
| `MLAT`               | Optional. Enable MLAT (true/false)                                                    | false          |

## Ports

No ports need to be mapped into this container.

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-opensky-network/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
