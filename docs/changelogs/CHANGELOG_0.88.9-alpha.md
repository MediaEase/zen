<h1>Changelog for version 0.88.9-alpha</h1>

<h2>🎉 New Features</h2>
<ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/9d627c7" class="commit-link" data-hovercard-type="commit">9d627c7</a></code> add support for executing user-defined files after downloading a git release (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/c89d28b" class="commit-link" data-hovercard-type="commit">c89d28b</a></code> enhance release retrieval process with version comparison and exit codes (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/0e83d4b" class="commit-link" data-hovercard-type="commit">0e83d4b</a></code> implement Radarr configuration reading function to extract API key and ports (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/1eef809" class="commit-link" data-hovercard-type="commit">1eef809</a></code> add Radarr authentication setup and refines service generation (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/8a70d89" class="commit-link" data-hovercard-type="commit">8a70d89</a></code> add prerelease check function to compare current version with GitHub releases (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
</ul>
<details>
  <summary>Show 7 more changes</summary>
  <ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/9855f0d" class="commit-link" data-hovercard-type="commit">9855f0d</a></code> add software reset functionality (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/536a1cb" class="commit-link" data-hovercard-type="commit">536a1cb</a></code> add software removal function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/b75e1ea" class="commit-link" data-hovercard-type="commit">b75e1ea</a></code> add function to retrieve application version via API (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/19b947d" class="commit-link" data-hovercard-type="commit">19b947d</a></code> context-based backup directory selection (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/16c6253" class="commit-link" data-hovercard-type="commit">16c6253</a></code> support for removing dependencies via apt (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/0738f9e" class="commit-link" data-hovercard-type="commit">0738f9e</a></code> add request management functions for API interactions in rhe new request.sh module (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/1800a55" class="commit-link" data-hovercard-type="commit">1800a55</a></code> update service_monitor.sh to retrieve monitored services from SQLite database (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
  </ul>
</details>

<h2>🩹 Bug Fixes</h2>
<ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/38649ab" class="commit-link" data-hovercard-type="commit">38649ab</a></code> enhance release version verification and error handling in git.sh (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/304db35" class="commit-link" data-hovercard-type="commit">304db35</a></code> service stop handling and adds delays (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/05d6d86" class="commit-link" data-hovercard-type="commit">05d6d86</a></code> add port_range to exported variables in autogen function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/9d643ad" class="commit-link" data-hovercard-type="commit">9d643ad</a></code> update infobox  to conditionally display username and password (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/4110512" class="commit-link" data-hovercard-type="commit">4110512</a></code> extract the correct user password (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
</ul>
<details>
  <summary>Show 3 more changes</summary>
  <ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/7d456e4" class="commit-link" data-hovercard-type="commit">7d456e4</a></code> vault initialization and key decoding issues (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/9944069" class="commit-link" data-hovercard-type="commit">9944069</a></code> remove redundant database query execution (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/0caea48" class="commit-link" data-hovercard-type="commit">0caea48</a></code> database file handling in zen_autocomplete script (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
  </ul>
</details>

<h2>🚀 Chores</h2>
<ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/7cd5592" class="commit-link" data-hovercard-type="commit">7cd5592</a></code> updates version numbers across multiple scripts (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/a10fa4a" class="commit-link" data-hovercard-type="commit">a10fa4a</a></code> add executable file paths for Lidarr, Sonarr, Readarr, Radarr, Prowlarr, and their 4K variants (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/8407579" class="commit-link" data-hovercard-type="commit">8407579</a></code> removes test executable file list (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/994bdbe" class="commit-link" data-hovercard-type="commit">994bdbe</a></code> enhance Radarr update process with additional checks and permissions (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/048b574" class="commit-link" data-hovercard-type="commit">048b574</a></code> simplify Radarr configuration function by removing prerelease argument and cleaning up comments (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
</ul>
<details>
  <summary>Show 2 more changes</summary>
  <ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/b80a75a" class="commit-link" data-hovercard-type="commit">b80a75a</a></code> add database path to Radarr configuration (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/e397463" class="commit-link" data-hovercard-type="commit">e397463</a></code> add validation for api_service declaration (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
  </ul>
</details>
<h2>🌐 Internationalization</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/fe7077c" class="commit-link" data-hovercard-type="commit">fe7077c</a></code> add new translation strings (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/ad74669" class="commit-link" data-hovercard-type="commit">ad74669</a></code> add new translations (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<h2>♻️ Refactors</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/9f831ca" class="commit-link" data-hovercard-type="commit">9f831ca</a></code> Radarr script (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/0f60deb" class="commit-link" data-hovercard-type="commit">0f60deb</a></code> update service validation to use configuration array and improve JSON handling (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/096b3a6" class="commit-link" data-hovercard-type="commit">096b3a6</a></code> service generation to use config array (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<div style="margin-top: 20px;"><strong>Full Changelog:</strong> <a href="https://github.com/MediaEase/zen/compare/v0.76.9-alpha...0.88.9-alpha" target="_blank">v0.76.9-alpha...0.88.9-alpha</a></div>