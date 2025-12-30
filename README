# Immich-Run
Organize photos and videos, manage Live Photos & GoPro files, and upload to Immich with flexible templates.

### Features
- Organize media into photo, video, and gopro folders.
- Detect Live Photos (photo + .mov) and keep them together.
- Prioritize GoPro .mp4 files over .lrv when both exist; delete .lrv if .mp4 exists.
- Delete unnecessary .aae and .thm files automatically.
- Flexible Immich upload templates with album support.
- Dry-run support for testing uploads without changing anything.
- Case-insensitive file handling.

### Prerequisites
- Linux or macOS environment (Bash compatible).
- immich-go installed and executable.
- .env file with:

```bash
IMMICH_GO_EXECUTABLE=/path/to/immich-go
IMMICH_SERVER=http://your-immich-server:2283
IMMICH_API_KEY=your-api-key
```

### Installation
- Clone the repository:

```bash
git clone https://github.com/shrestha-bishal/immich-run.git
cd immich-run
```

- Set up .env with your Immich configuration.
```bash
mv .env.example .env
```

- Make sure scripts are executable:
```bash
chmod +x immich-run.sh
chmod +x scripts/*.sh
```

### Usage
- Basic command:
```bash
./immich-run.sh -o -u TEMPLATE [ALBUM] -s "/path/to/source"
```

- Options:
| Short | Long        | Arguments              | Description                                                                 |
|------:|-------------|------------------------|-----------------------------------------------------------------------------|
| -o    | --organise  | —                      | Organize the media folder.                                                   |
| -u    | --upload    | TEMPLATE [ALBUM]       | Upload using a specific template. If the template requires an album, provide the album name. |
| -s    | --source    | PATH                   | Source folder to organize/upload. Mandatory.                                |
| -h    | --help      | —                      | Show help message.                                                          |

### Examples
- Organize and upload to the Uploads album (default):
```bash
./immich-run.sh -o -u -s "/mnt/media/2025-08-27 Trip"
```

- Upload using a specific template with a custom album:
```bash
./immich-run.sh -u into_album_tag "My Trip Album" -s "/mnt/media/2025-08-27 Trip"
```

- Dry-run upload (using .upload-templates.env):
```bash
./immich-run.sh -u dry_run -s "/mnt/media/2025-08-27 Trip"
```

### Upload Templates
Defined in upload-templates.env. Example templates:
```bash
dry_run="--dry-run"
album_by_folder_tag="--folder-as-album FOLDER --folder-as-tags"
album_by_path_tag="--folder-as-album PATH --folder-as-tags"
into_album_tag="--into-album {{ALBUM}} --folder-as-tags"
into_album="--into-album {{ALBUM}}"
```

> Note: Do not include server or API key in templates; only arguments for immich-go.

### License
MIT License. See [LICENSE](./LICENSE)  for details.

### Contributing
- Fork the repo, make changes, and submit a pull request.
- Report bugs or feature requests via GitHub issues.


### Funding & Sponsorship
`immich-run` is an open-source tool developed and maintained to simplify and automate media organisation and uploads for Immich users.
If you or your organisation find this project useful, please consider supporting its ongoing development.

Your sponsorship helps ensure long-term maintenance, improved features, better documentation, and continued compatibility with future Immich releases—while keeping the project free and open for the community.

As a token of appreciation, sponsors may have their logo and link featured in the project README and documentation.
Priority support and early access to planned features may also be offered where appropriate.

### Support Options
[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-Become%20a%20Sponsor-blueviolet?logo=githubsponsors&style=flat-square)](https://github.com/sponsors/shrestha-bishal)  
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20Developer-yellow?logo=buymeacoffee&style=flat-square)](https://www.buymeacoffee.com/shresthabishal)  
[![Thanks.dev](https://img.shields.io/badge/Thanks.dev-Appreciate%20Open%20Source-29abe0?logo=github&style=flat-square)](https://thanks.dev/gh/shrestha-bishal)  

---

### Author
**Bishal Shrestha**  

[![GitHub](https://img.shields.io/badge/GitHub-Profile-black?logo=github)](https://github.com/shrestha-bishal)  
[![Repo](https://img.shields.io/badge/Repository-GitHub-black?logo=github)](https://github.com/shrestha-bishal/immich-run)

© 2025 Bishal Shrestha, All rights reserved  