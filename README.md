# i

`i` is a very simple terminal-based micro-journal built on git. 

It takes a couple of ideas from other journaling systems and mixes them with git, to enable easy distribution of the journal between different systems. 

It provides some easy ways of presenting the data along with integration with the GPT API to perform analyis of specific time windows in your journal. 

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

### List entries between time range

```bash
❯ i list since "30 minutes ago"

21 minutes ago: went for a walk

❯ i list until "60 minutes ago"

79 minutes ago: created a journal

❯ i list until "50 minutes ago" since "60 minutes ago"

54 minutes ago: spoke to @john

54 minutes ago: added an entry

❯ i list since "60 minutes ago" until "50 minutes ago"

54 minutes ago: spoke to @john

54 minutes ago: added an entry
```

> See the official git documentation, [date-formats.txt](https://raw.githubusercontent.com/git/git/master/Documentation/date-formats.txt) for all possible date and time representations `since` and `until` support.

### List mentions

```bash
❯ i mentioned
   2 @john
   2 @fred
   1 @linda
   1 @kelly
```

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

## GPT Integration

The following actions use the GPT API. For this to work you need `GPT_ACCESS_TOKEN` to be set in your environment. 

To generate an OpenAI key, go to [https://platform.openai.com/account/api-keys](https://platform.openai.com/account/api-keys) and create a new key. 

You can configure the version of the GPT API to use by setting `I_GPT_VERSION` in your environment. The default is gpt-4. 

### Get a digest

You can use `i` to make a weekly digest using your notes. 

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

### Be reminded of things from last week

Using the GPT API you can ask `i` to remind you of things from last week. 

```bash
❯ i remember
- Catch up with **Kelly**
```

### Analyse your journal 

You can use the GPT API to easily analyse your journal with arbitrary prompts. 

```bash
❯ i analyse since "2 days ago" give me a list of names from this along with a sentiment analysis of the conversations
Names mentioned:
1. John
2. Fred 
3. Linda
4. Kelly

Sentiment analysis of the conversations:

1) Conversations with John: Neutral to positive, discussing technical issues and solutions.
2) Conversations with Fred: Neutral to positive, providing guidance and discussing progress on projects.
3) Conversations with Linda: Neutral to positive, discussing technical issues and solutions.
```

## Execute arbitrary git commands

Your journal is just a git repo and the entries are just empty commits with a commit message. 

By running `i git` you can run any git command on its repo. 

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

### Push to a remote

```bash
i git push
```

## Log commits made in other repositories to i.sh

A post-commit hook provided in `.githooks/post-commit` which will then automatically log commits using `i.sh`.

Commits will then be logged in the following format as they are made:

```
34 minutes ago: [repo:i] (branch:main) cmsg: 'doc: Update README with post-commit hook'
```

You can install it either for a specific repository or globally for all your repositories.

### Log commits for a specific repository

1. Modify your PATH variable to include this repository, or place `i.sh` on your PATH.
2. Copy `.githooks/post-commit` into `.git/hooks`

### Log commits for all repositories

1. Modify your PATH variable to include this repository, or place `i.sh` on your PATH.
2. From the root of this repository, run `git config --global core.hooksPath $PWD/.githooks`
