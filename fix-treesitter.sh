#!/bin/bash

# Script to fix nvim-treesitter local changes

echo "Removing local changes from nvim-treesitter..."
cd ~/.local/share/nvim/lazy/nvim-treesitter

echo "Checking git status..."
git status

echo "Resetting to HEAD..."
git checkout -- .

echo "Done. Now open nvim and run :Lazy update"
echo "Or run: nvim --headless -c 'Lazy update' -c 'qa'"
