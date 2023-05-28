# i

`i` is a very simple terminal-based micro-journal built on git. 

It takes a couple of ideas from other journaling systems and mixes them with git, to enable easy distribution of the journal between different systems. 

## install

Requires `git`

```bash
source i.sh #this creates your journal repo at ~/i
```

## how

### Add jornal entries. 

```bash
❯ i added an entry
❯ i spoke to @john
❯ i had a meeting with @john and @linda, we discussed %project
...
❯ i went for a walk
```

### List entries

```bash	
❯ i list
21 minutes ago: went for a walk

45 minutes ago: had another conversation with @fred about %anotherproject and he told me to speak to @kelly

45 minutes ago: had a coffee with @fred, he told me about %anotherproject

45 minutes ago: had a meeting with @john and @linda, we discussed %project

54 minutes ago: spoke to @john

54 minutes ago: added an entry

79 minutes ago: created a journal
```

> You can 'mention' names with `@` and 'tag' things with `%`.

### List mentions

```bash
❯ i mentioned
   2 @john
   2 @fred
   1 @linda
   1 @kelly
```` 

### List specific entries for people

```bash
❯ i mentioned john
44 minutes ago: had a meeting with @john and @linda, we discussed %project
53 minutes ago: spoke to @john
```

### List tags

```bash
❯ i tagged
   2 %anotherproject
   1 %project
```

### List entries which mention specific tags

```bash
❯ i tagged project
46 minutes ago: had a meeting with @john and @linda, we discussed %project
```

### Count Occurrences

```bash
❯ i occurrences told
   2 told
```


### Find things

```bash
❯ i find told
51 minutes ago: had another conversation with @fred about %anotherproject and he told me to speak to @kelly
51 minutes ago: had a coffee with @fred, he told me about %anotherproject
```

### Get a digest

You can use `i` to make a weekly digest using your notes. For this to work you need `GPT_ACCESS_TOKEN` to be set in your environment. 

```bash
❯ i digest
# Project
- Had a meeting with **John** and **Linda**
- Discussed **Project**

# AnotherProject
- Had another conversation with **Fred**, he told me to speak to **Kelly**
- Had a coffee with **Fred**, he told me about **AnotherProject**

# General Updates
- Went for a walk
- Spoke to **John**
- Added an entry
- Created a journal
```




## Execute arbitrary git commands

Your journal is just a git repo, by running `i git` you can run any git command on its repo. 

```
i git log
commit 34c842819947b7fd6b8bfb1d0fae1ab7c6516058 (HEAD -> master)
Author: You <you@email.com>
Date:   Fri Apr 30 00:11:53 2021 +0100

    went for a walk

commit 56f1aefb2c0e4704c21d9d82783b08a92a6839b3
Author: You <you@email.com>
Date:   Thu Apr 29 23:54:19 2021 +0100

    had another conversation with @fred about %anotherproject and he told me to speak to @kelly

commit 74fc4de053bfb6d6f4c...
```

### Add a remote

```bash
i git remote add origin git@my-git.lb.local:me/myi.git
```
