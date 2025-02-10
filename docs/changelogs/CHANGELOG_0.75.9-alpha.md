<h1>Changelog for version 0.75.9-alpha</h1>
<h2>🎉 New Features</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/b8cd03c" class="commit-link" data-hovercard-type="commit">b8cd03c</a></code> (grafana) add grafana preliminary support (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/4ead1af" class="commit-link" data-hovercard-type="commit">4ead1af</a></code> <code>zen::software::port_randomizer</code> add a condition for generate grafana port ranges (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/cd7125a" class="commit-link" data-hovercard-type="commit">cd7125a</a></code> (workspace) <code>zen::workspace::go::build</code> function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/bd9c679" class="commit-link" data-hovercard-type="commit">bd9c679</a></code> (workspace) <code>zen::workspace::go::uninstall</code> function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/07aa11f" class="commit-link" data-hovercard-type="commit">07aa11f</a></code> (workspace) <code>zen::workspace::go::install</code> function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>

<h2>🩹 Bug Fixes</h2>
<ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/f6a1c2c" class="commit-link" data-hovercard-type="commit">f6a1c2c</a></code> update software options processing to include prerelease status based on branch value (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/542306f" class="commit-link" data-hovercard-type="commit">542306f</a></code> update software options handling to use software_options for improved consistency (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/fc92a3e" class="commit-link" data-hovercard-type="commit">fc92a3e</a></code> update software configuration handling to use options for improved consistency (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/4fa0497" class="commit-link" data-hovercard-type="commit">4fa0497</a></code> add release_name entries for various software configurations (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/5ab2ea9" class="commit-link" data-hovercard-type="commit">5ab2ea9</a></code> refactor Radarr functions to use config variables for improved consistency and maintainability (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
</ul>
<details>
  <summary>Show 6 more changes</summary>
  <ul>
    <li><code><a href="https://github.com/MediaEase/zen/commit/16ce1ec" class="commit-link" data-hovercard-type="commit">16ce1ec</a></code> update software options handling to include software_version and prerelease status (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/81f35e4" class="commit-link" data-hovercard-type="commit">81f35e4</a></code> update jq commands to use variables for improved readability and maintainability (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/7a1f762" class="commit-link" data-hovercard-type="commit">7a1f762</a></code> update database file path retrieval to use environment variable (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/5838d59" class="commit-link" data-hovercard-type="commit">5838d59</a></code> streamline database query execution and improve error handling (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/8a12c4f" class="commit-link" data-hovercard-type="commit">8a12c4f</a></code> add session_id to user_columns in user loading function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/27918e8" class="commit-link" data-hovercard-type="commit">27918e8</a></code> add missing multi-user support in Readarr4K configuration (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
  </ul>
</details>
<h2>🏗️ Build System & Dependencies</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/9a7fa11" class="commit-link" data-hovercard-type="commit">9a7fa11</a></code> add grafana dependencies (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/49a70af" class="commit-link" data-hovercard-type="commit">49a70af</a></code> add telegraf apt source (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/5c957ac" class="commit-link" data-hovercard-type="commit">5c957ac</a></code> add fluentbit apt source (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/67000ef" class="commit-link" data-hovercard-type="commit">67000ef</a></code> add grafana apt source (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<h2>🚀 Chores</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/d04d2ce" class="commit-link" data-hovercard-type="commit">d04d2ce</a></code> update software repository references to use config array (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/05ace46" class="commit-link" data-hovercard-type="commit">05ace46</a></code> adds ui_options to various software configurations (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/3342623" class="commit-link" data-hovercard-type="commit">3342623</a></code> removes deprecated port configurations from various software configs (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/23960e6" class="commit-link" data-hovercard-type="commit">23960e6</a></code> updates group classifications in config files (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li>
<li><code><a href="https://github.com/MediaEase/zen/commit/6d93a49" class="commit-link" data-hovercard-type="commit">6d93a49</a></code> removes deprectaed description fields from config files (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<h2>🤷 Other Changes</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/74e6aba" class="commit-link" data-hovercard-type="commit">74e6aba</a></code> Simplifies Go build function (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<h2>Other Changes</h2>
<ul><li><code><a href="https://github.com/MediaEase/zen/commit/cde595b" class="commit-link" data-hovercard-type="commit">cde595b</a></code> update copyright notice (<a href="https://github.com/tomcdj71" class="user-mention notranslate">@tomcdj71</a>)</li></ul>
<div style="margin-top: 20px;"><strong>Full Changelog:</strong> <a href="https://github.com/MediaEase/zen/compare/v0.70.9-alpha...0.75.9-alpha" target="_blank">v0.70.9-alpha...0.75.9-alpha</a></div>