
for item in `git diff --name-only main..HEAD | grep \\.sh$ | grep ^scripts\\/`
do
    chmod +x $item
    bash $item
done