# review-tags

This tool is built for teams who force-push changes to feature branches during PR review.
It can help you keep track of code versions you've reviewed by creating tags whenever you've completed a review or re-review.

## Installation

Put `review-tags.sh` in your path somewhere. Some prefer a short alias (e.g. `rt`) others prefer to hook it up as a custom git command (e.g. including it in your path as `git-review` allows you to invoke the script with `git review`).

## Usage and Flow

When you start a review, you can checkout the branch manually or let the script do it for you with `rt pull my-feature`.

**Note:** The `pull` command will perform a `git fetch`.

You'll notice that the script creates a new tag named `review/origin/my-feature/1`, which marks the specific commit that you reviewed.

When the author force-pushes a change, you can run `rt pull` (no arguments implies current branch) to fetch the latest commit, update your local branch to this new commit, and create a new review tag (e.g. `review/origin/my-feature/2`).

You can view a plain diff of the change by doing `rt diff 1 2` or simply `rt diff` which implies the last and second-to-last tags.

Often, a plain diff isn't valuable because the author might have rebased on the base branch. It's often more valuable to do `rt range-diff` to show a [range-diff](https://git-scm.com/docs/git-range-diff) between the commits. This is effectively a "diff-diff" which shows what the author has changed in their own commits.

# Lazygit Custom Command Example

This command allows you to optionally provide a branch name in a prompt response. If unset, `rt` will default to pulling the locally checked out branch.

```
- key: "v"
  description: "rt pull branch"
  command: "rt p {{index .PromptResponses 0}}"
  context: "localBranches"
  prompts:
    - type: 'input'
      title: 'Branch Name:'
```
