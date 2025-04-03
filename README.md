# sdre-enthusiasts/docker-sdrmap

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [SDR Map's](http://sdrmap.org) feeder scripts. Designed to work in tandem with [sdr-enthusiasts/docker-adsb-ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder). Builds and runs on `x86_64`, `arm64`, and `arm32v7`.

## Obtaining credentials to feed

Please visit [feeding](https://github.com/sdrmap/docs/wiki/2.1-Feeding) for instructions on how to obtain credentials to feed. Once you have credentials (a username and password), you can proceed with setting up the container.

## Up-and-Running with Docker Compose

```yaml
services:
  sdrmap:
    image: ghcr.io/sdr-enthusiasts/docker-sdrmap:latest
    container_name: sdrmap
    restart: always
    environment:
      - TZ=America/New_York
      - BEASTHOST=ultrafeeder
      - LAT=-33.33333
      - LON=111.11111
      - ALT=99
      - SMUSERNAME=yourusername
      - SMPASSWORD=yourpassword
      - SEND_SYSINFO=true
      - MLAT_PRIVACY=false
    tmpfs:
      - /tmp
      - /run:exec,size=64M
      - /var/log
```

## MLAT

MLAT is enabled by default. If you want to disable MLAT, you need to set the `MLAT` environment variable to `false`.

For MLAT to work, make sure to include the `ALT` environment variable with the altitude of your antenna in meters. For example, if your antenna is 10 meters above sea level, you would set `ALT=10`. If your `ALT` parameter is not set, MLAT will not work.

You will want to send mlat results to ultrafeeder using this environment variable:

```yaml
- MLAT_RESULTS=beast,connect,ultrafeeder:31004
```

The container also provides MLAT results on port 30105. Alternatively, you could pull these results from the SDRMap container. For Ultrafeeder, this would mean adding a line to the `ULTRAFEEDER_CONFIG` parameter like this:

```yaml
- ULTRAFEEDER_CONFIG=
    ...
    mlathub,sdrmap,30105,beast_in;
```

### MLAT Privacy

> [!WARNING]
> When MLAT is enabled, you station position (rounded to 2 decimals for lat/lon) is shown on the SDRMap website, which means it will be accurate within about 1 km.
> If you would rather not show your station position at all, set `MLAT_PRIVACY` to `true`

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                                                                                  | Default        |
| -------------------- | ---------------------------------------------------------------------------------------- | -------------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090/readsb)                       |                |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090/readsy)                     | 30005          |
| `SMUSERNAME`         | Required. The `yourusername` username provided by SDRMap                                                                        |  |
| `SMPASSWORD`         | Required. The `yourpassword` password provided by SDRMap Password                                                               |  |
| `LAT`                | Required. Latitude of the antenna                                                        |                |
| `LON`                | Required. Longitude of the antenna                                                       |                |
| `ALT`                | For MLAT set the altitude in **_meters_**. No trailing `m` or other values necessary.    | Unset          |
| `TZ`                 | Optional. Your local timezone                                                            | GMT            |
| `MLAT`               | Optional. Enable MLAT (true/false)                                                       | false          |
| `MLAT_RESULTS`       | Optional. Add --results output to mlat-client (example: beast,connect,ultrafeeder:31004) | false          |
| `MLAT_PRIVACY`       | Optional. Set to true to hide your station on the SDRMap website                        | false          |
| `SEND_SYSINFO`       | Optional. Set to true to share some system information (CPU, speed, memory use, readsb/mlat-client versions, etc.) with SDRMap. This information may be shown on the SDRMap webpage. | false |

## Ports

No ports need to be mapped into this container.

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-sdrmap/issues) on the project's GitHub.

We also have a [Discord server](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
