fb_bookworm
===========

Bookworm is a program that gleans context from a Chef/Ruby codebase, which
recognizes that Ruby source files in different directories have different
semantic meaning to a larger program (ie Chef)

It currently runs on top of the Chef Workstation Ruby, although there is
nothing preventing running bookworm on vanilla Ruby using bundler, etc.

Usage
-----

Bookworm is designed to be installed via Chef cookbook as well as running
directly from the cookbook. This assumes you have at least [Chef Workstation
20](https://www.chef.io/downloads/tools/workstation) installed. If you run this
cookbook in a Chef run, it will also install Bookworm into
`/usr/local/lib/bookworm` (with a shell script launcher at
`/usr/local/bin/bookworm`)

```
# If you're running directly from the cookbook
cd files/default/bookworm

# Get the program flags
$ ./bookworm.rb -h
Usage: bookworm.rb [options]
        --report CLASS               Give the (class) name of the report you'd like
        --list-reports               Get the (class) names of available reports
        --list-rules                 Get the (class) names of available inference rules

Debugging options:
        --irb-config-step            Open IRB REPL after loading configuration
        --irb-crawl-step             Open IRB REPL after crawler has run
        --irb-infer-step             Open IRB REPL after inference has run
        --irb-report-step            Open IRB REPL after report is generated

# Get a list of reports that can be run
$ bookworm --list-reports
AllReferencedRecipes    Determines all recipes that are directly referenced by all roles
AllRoleDescriptions     Basic report to show extraction of description from roles
...

# Run a report
$ bookworm --report AllRoleDescriptions
```

Configuring Bookworm
--------------------

Bookworm currently checks 2 different places for configuration,
`~/.bookworm.yml` and `/usr/local/etc/bookworm/configuration.rb`

### ~/.bookworm.yml

A typical bookworm YAML configuration would look something like this:

```yaml
# A basic chef layout
source_dirs:
  cookbook_dirs:
    - /absolute/path/to/cookbooks
    - /absolute/path/to/some/other/cookbooks
  role_dirs:
    - /absolute/path/to/role/files
debug: false   # Additional debug information
```

### /usr/local/etc/bookworm/configuration.rb

If you need to programmatically determine what your `source_dirs` are (ie if
you don't know what directories Bookworm will be running on ahead of time), you
can use `/usr/local/etc/bookworm/configuration.rb` to set `DEFAULT_SOURCE_DIRS`
and `DEFAULT_DEBUG`. This might be overkill for your needs, and
`~/.bookworm.yml` is probably your best bet.

Glossary
--------

### Bookworm key

A bookworm key is a type of file, and all the information that should be
necessary to handle that file throughout the Bookworm pipeline. By
encapsulating the "what" and the "how" of a file here, adding new types of
files to Bookworm shouldn't involve more than adding a new key.

Of note, a 'metakey' isn't a file - it could be a concept or a group of files.
This is particularly useful with Chef code, since the notion of a 'cookbook' is
several things, and rather than doing backflips trying to match information to
specific files within a cookbook directory, it's much simpler to say "this
cookbook provides this resource/class/attribute."

### Crawler

The crawler is what transforms whatever the key finds into a navigable Ruby
representation of the file (for Ruby files, this would be an AST representation
of the source file as generated by the rubocop-ast gem).

### KnowledgeBase

The KnowledgeBase is the singleton object that holds all Ruby representations
of the crawled files, as well as all information derived by the Bookworm rules.

### Rule

A 'rule' in Bookworm is an auto-generated class that takes the crawled
representation of a file and extracts specific information about it. If you
want to know about 3 unrelated patterns in a source file, consider using (or
writing, if they don't exist yet) 3 rules. Small rules encourage re-use in
reports, and since rules can reference information about a file derived from
*other* rules, this is a good place to do any heavy lifting when figuring out
what's going on with your keys.

### InferEngine

The InferEngine runs the necessary rules against each key that was crawled.

### Reports

The report takes the information that you've extracted from the codebase, and
pulls it together into a human or machine-readable representation. While this
is a good place to store specific logic for representation, it doesn't hurt to
ask 'how do I delegate the hard work to rules' - think of reports as the glue
that pulls together a bunch of derived facts into something nice that you can
hand to your boss ;-)

Guiding design principles
-------------------------

* Easy and fast iteration
   * Writing a Bookworm rule or report should be as easy as grabbing bash and
     grep
   * Profiling and debugging hooks should be in strategic spots to make it easy
     to debug
* Each new rule or report unlocks the potential for new discoveries
   * It should be easy to use existing work, so that building reports is just a
     matter of grabbing existing rules (or other reports)
* Zero-cost additions, so you only analyze/execute the report (and supporting
  rules) that are needed
   * A slow rule shouldn't matter unless you're actually using it
   * Accept that copy-paste is going to happen with rules and reports, and make
     that simple.

Implementation notes - Why Rubocop for AST generation
-----------------------------------------------------

Because we wanted to use something that was already in Chef Workstation, the
two choices were Ripper or Parser a la RuboCop (ruby_parser uses racc which has
a C extension, but no sexp pattern matcher that I know of).

Ripper is fast, but the sexp output is kind of nasty, and cleaning that up
could be a big timesuck. Since the larger Ruby/Chef community has a bit more
familiarity with Parser/RuboCop's node pattern matching, it'd be better to stay
with that for now (there's no reason this couldn't be migrated later with
helpers to translate patterns). Work could also be done to speed up RuboCop
(ractor and async support could go a long way here).
