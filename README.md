---

# Prerequisites:

- ruby >= 3.2
- git

---

# Installation:

1. Clone the repo:
```
git clone https://github.com/puppy-console/puppy-fetch
```
2. Move into the directory:
```
cd puppy-fetch
```

# Using the CLI:

1. Add an alias (`RECOMMENDED`):
```
alias puppy-fetch="ruby -I lib bin/puppy-fetch"
```

2. Run ( `puppy-fetch -h` for help with options ):
```
puppy-fetch <owner> <repo> [OPTIONS]
```

# Using the library:

1. Build the gem:

```
gem build .gemspec
```

2. Require the gem: 

```
require 'puppy-fetch'
```

---
