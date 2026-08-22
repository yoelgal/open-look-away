# Harvest archive

One folder per ingested source.

```
raw/sources/<YYYY-MM-DD>-<type>-<slug>/
  source.md      # frontmatter + depth ladder + FEEDS
  article.md     # cleaned canonical text / product brief
  media/         # images, screenshots, downloaded assets
```

## source.md frontmatter

```yaml
title:
type:        # site | article | repo | post | video
author:
url:
date:        # source date if known
captured:    # YYYY-MM-DD
extraction:  # reader + browser + images
tags: []
feeds:       # what this source is for in this repo
```

## Depth ladder

Every `source.md` must have `## Depth ladder` with seven rungs. Each line is:

`N. Name - CAPTURED. <what was read>.`

or

`N. Name - SKIPPED: <no such layer | commodity content | paywalled | out of assigned scope | unrecoverable with the routes tried named>.`

## Manifest

`raw/sources/manifest.md` lists each batch item, status, files, and who extracted it.
