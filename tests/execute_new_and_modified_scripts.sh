current_commit=`git rev-parse HEAD`
for item in `git diff --name-only main..$current_commit | grep \\.sh$ | grep ^scripts\\/`
do
    chmod +x $item
    bash $item
done