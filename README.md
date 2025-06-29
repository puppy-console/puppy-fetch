# Prerequisites:

---

- ruby >= 3.2
- bundle >= 2.4.1
- git

---

# Installation

1. Add to Gemfile:
```rb
gem "puppy-fetch", git: "https://github.com/puppy-tools/puppy-fetch.git"
```

2. Bundle Install:
```sh
bundle install
```

# Usage

- As CLI:
```
bundle exec puppy-fetch 
```

- As Library:
```rb
require 'puppy-fetch'
```

# Troubleshooting

| ✖️ Problem                                          | ✔️ Solution                                                                                                       |
|-----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
|  `Unable to retrieve repository from 'owner/repo'.` | `- You have a typo in your owner name or repository name.`<br>`- You have exceeded your rate limit for the hour.` |  

---
