---
title: "Git Autosquashing"
date: 2023-03-28T22:29:22+02:00
draft: false
toc: false
images:
tags:
  - tips
  - git
---

## Autosquashing

A quick tip this time.

Sometimes you stumble on that one blog post that dramatically improves your life.
[Autosquashing Git Commits](https://thoughtbot.com/blog/autosquashing-git-commits) post from thoughtbot was
such an improvement for me recently.

### The problem

You're working on a merge request, pushing commit after commit. You're in "the flow".

Suddenly you realize - in the commit you've just pushed, there is a bug/typo/simple mistake, whatever.
You want to change it, but the commit is already there. Easy peasy, just `git commit --amend` it. Done.

But... what if you committed `A`, then committed `B`, but while working on `C` you've found a bug that
`A` introduced? Or a change that really should've been placed along with the commit `A`?

### The solution

Usually, at this stage, I committed the change, then I did `git rebase --interactive HEAD~4` or something like that,
then I moved commits around and used either `fixup` or `squash`. It does work, but it's not ideal. It involves many steps, you need to manually
rearrange the commits every single time. It's distracting.
Of course, I could just move ahead and rebase at the very end, but I'm sure that I'd forget that, especially if there were more commits like that.

Is there a better way? Sure, that's the whole point of this post! Actually, there are two better ways:

- `git commit --fixup <rev>`
- `git commit --squash <rev>`

What's that? Easy. The `fixup` one, commits your changes, but automatically creates a commit message so that it will contain `fixup! <message of rev>`. Squash works analogously, but creates `squash! <message of rev>`.

Why is that so neat? Well, because now, when you run `git rebase --interactive --autosquash ...` (notice the last flag) then git
will automatically place your commits correctly (right after the `rev` you specified) and will add the proper rebase verb (`fixup` or `squash`).

Great! I had one instant question: how can I tell git to always use `--autosquash`? Well: `git config --global rebase.autosquash true`. Done.

One last thing. Finding the `<rev>` to `fixup` or `squash` is a little inconvenient. Usually, I open `git log`, copy the sha, etc... Is there an easier way? Sure! This is another thing I've learned from that article: you can refer to commits by their commit message! So to `fixup` a commit with the message "fix: null reference bug" you can just use `git commit --fixup :/null`. Note that
this will always refer to the _latest_ commit with the matching message, keep that in mind.

### Quick example

Current state:

```bash
commit 000e92965066ad7494b392ec51e3f573777ef1b4 (HEAD -> main, origin/main)
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:25:57 2023 +0200

    refactor(shell): starship tuning

commit d52f126d62c020bfdb7782594d5d69e146c80ab3
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:15:23 2023 +0200

    feat(tmux): cleaner theme

commit c7311af61600e7f13c31f472840d9fbd08d391c0
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 18:22:35 2023 +0200

    feat(shell): add flash-to and enable shlvl
```

Let's assume I've changed some files related to shlvl configuration ([starship](https://starship.rs/config/#shlvl)) and
want to add them to `c7311af6`:

```bash
$ git commit --fixup :/shlvl
```

New state:

```bash
commit 5c62951708d2f75cbedc7810f467c001105e541e (HEAD -> main)
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 23:03:18 2023 +0200

    fixup! feat(shell): add flash-to and enable shlvl

commit 000e92965066ad7494b392ec51e3f573777ef1b4 (origin/main)
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:25:57 2023 +0200

    refactor(shell): starship tuning

commit d52f126d62c020bfdb7782594d5d69e146c80ab3
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:15:23 2023 +0200

    feat(tmux): cleaner theme

commit c7311af61600e7f13c31f472840d9fbd08d391c0
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 18:22:35 2023 +0200

    feat(shell): add flash-to and enable shlvl
```

Now:

```bash
# no need for --autosquash if you've set the global option like me
$ git rebase --autosquash --interactive @~5
```

What git rebase windows shows (notice all commits are already correctly reordered and with proper verbs):

```bash
pick f041654 feat: rpi4 images as packages
pick c7311af feat(shell): add flash-to and enable shlvl
fixup 5c62951 fixup! feat(shell): add flash-to and enable shlvl
# here ^
pick d52f126 feat(tmux): cleaner theme
pick 000e929 refactor(shell): starship tuning
```

And finally, after rebase:

```bash
commit c0fc2e83937b55d2ed95ab986ff636acb4da1939 (HEAD -> main)
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:25:57 2023 +0200

    refactor(shell): starship tuning

commit 21c8c26f44fc117c457df37b2973cbbb2a150122
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 22:15:23 2023 +0200

    feat(tmux): cleaner theme

commit 74666cc140411c11f3b20f7c911cf10cf64f11db
Author: Konrad Malik <konrad.malik@gmail.com>
Date:   Tue Mar 28 18:22:35 2023 +0200

    feat(shell): add flash-to and enable shlvl
```

Done!

### Conclusion

First, read the [original article](https://thoughtbot.com/blog/autosquashing-git-commits).

Second, enable `rebase.autosquash` in your git config.

Third, if referring to revs by a part of a message blew your mind just like mine, type `man gitrevisions`, read it, and thank me later.
