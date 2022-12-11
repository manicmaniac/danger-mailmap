# danger-mailmap

[![Test](https://github.com/manicmaniac/danger-mailmap/actions/workflows/test.yml/badge.svg)](https://github.com/manicmaniac/danger-mailmap/actions/workflows/test.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/0b6932dadcec9c9b8484/maintainability)](https://codeclimate.com/github/manicmaniac/danger-mailmap/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/0b6932dadcec9c9b8484/test_coverage)](https://codeclimate.com/github/manicmaniac/danger-mailmap/test_coverage)

A Danger plugin to check if .mailmap has a canonical name of author and committer.

## Installation

```sh
gem install danger-mailmap
```

Or write the following code in your Gemfile.

```ruby
gem 'danger-mailmap'
```

## Usage

The easiest way to use is just add this to your Dangerfile:

```ruby
mailmap.check
```

If your repository has a mailmap file located in the place other than `.mailmap`, you can pass the path as argument.

```ruby
mailmap.check '/path/to/mailmap'
```

If you want `danger-mailmap` to ignore a particular user regardless of mailmap, set `allowed_patterns`.

```ruby
mailmap.allowed_patterns = [
  /.+@(users\.noreply\.)?github\.com/,
  'good@example.com'
]
mailimap.check
```

## What is mailmap?

`mailmap` is a file that maps Git author and committer names and/or email addresses.

See `man 5 gitmailmap` or https://git-scm.com/docs/gitmailmap for the detail.

## How to fix warnings

If you encountered warnings like *email@example.com is not included in .mailmap*, basically you have 4 options.

1. Rewrite author and/or committer of each commit in the pull request.
2. Add new entry to mailmap.
3. Add new allow-list entry to Dangerfile.
4. Do nothing and remain everything as-is.

If you don't want to continue using `email@example.com`, `1.` is the most preferable option.
See [How to rewrite author and/or committers](#how-to-rewrite-author-andor-committers) section.

If it is the first time for you to contribute to the repository, you may want to choose the option `2.`.
Just add `Your Name <email@example.com>` to the mailmap file and commit it.

If `email@example.com` is an email address of a bot user and it can vary, you can add it to allow-list.
For example, [renovate](https://github.com/renovatebot/renovate) bot has variable email like `29139614+renovate[bot]@users.noreply.github.com`.
See [Usage](#usage) section to know how to use `mailmap.allowed_patterns`.

Lastly, when you clearly know what you are doing or you have your teammates' permission, the option `4.` is obviously the most easiest way.

## How to avoid making commits with unintended author/committer email

You need to tell Git to use the correct name and email like the following:

```sh
git config --global user.email 'correct@example.com'
git config --global user.name 'Correct Name'
```

If you have multiple names or emails and changes them by repository, you may want to set name and email to the specific repository.

Use `--global` option instead of `--local` in this case.

```sh
git config --local user.email 'correct@example.com'
git config --local user.name 'Correct Name'
```

## How to rewrite author and/or committers

You can rewrite existing commits' author and/or committer in a pull request with `git filter-branch` command.

Let's say that you made a pull request with `wip` branch based on `master` branch and `danger-mailmap` complains *`old@example.com` is not included in mailmap*. You want to change `old@example.com` to `new@example.com` with the proper name `New One`.

In this case, the following script works well.

```sh
git filter-branch --env-filter '
    if [ "$GIT_AUTHOR_EMAIL" = "old@example.com" ]; then
        GIT_AUTHOR_EMAIL="new@example.com"
        GIT_AUTHOR_NAME="New One"
    fi
    if [ "$GIT_COMMITTER_EMAIL" = "old@example.com" ]; then
        GIT_COMMITTER_EMAIL="new@example.com"
        GIT_COMMITTER_NAME="New One"
    fi
' --tag-name-filter cat master...wip
```

Perhaps you may want to undo the changes.

Don't worry, `git filter-branch` automatically backups the original history.
The following command rollbacks the previous changes.

```sh
git reset --hard original/refs/heads/wip
```

By default, `git filter-branch` does not run when a backup for the current branch exists.

You can delete it by running:

```sh
git update-ref -d refs/original/refs/heads/wip
```

Or just pass `--force` option to the next `git filter-branch` command to overwrite existing backups.

See [the official document](https://git-scm.com/docs/git-filter-branch) for other examples of `git filter-branch`.

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
