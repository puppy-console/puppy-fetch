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

3. Using CLI:
```
bundle exec puppy-fetch GITHUB_OWNER GITHUB_REPO [options]
```

4. Using Library:
```rb
require 'puppy-fetch'
```

---
