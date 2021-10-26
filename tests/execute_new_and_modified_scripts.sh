latest_main_commit=`git log -n 1 --pretty=format:"%H"`
current_commit=`git rev-parse HEAD`
for item in `git diff --name-only $latest_main_commit $current_commit | grep \\.sh$ | grep ^scripts\\/`
do
    chmod +x $item
    bash $item
done