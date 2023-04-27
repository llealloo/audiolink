array=(
"./AudioLinkUnityProject/AudioLink.csproj"
"./AudioLinkUnityProject/AudioLink.Editor.csproj"
"./AudioLinkUnityProject/AudioLink.Extras.csproj"
"./AudioLinkUnityProject/AudioLink.Extras.Editor.csproj"
)

for i in ${array[@]}
do
	dotnet format $i
done
