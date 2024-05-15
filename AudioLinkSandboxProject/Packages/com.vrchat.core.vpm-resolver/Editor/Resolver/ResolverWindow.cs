using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;
using VRC.PackageManagement.Core;
using VRC.PackageManagement.Core.Types;
using VRC.PackageManagement.Core.Types.Packages;
using Version = VRC.PackageManagement.Core.Types.VPMVersion.Version;

namespace VRC.PackageManagement.Resolver
{
    public class ResolverWindow : EditorWindow
    {
        // VisualElements
        private static VisualElement _rootView;
        private static Button _refreshButton;
        private static Button _createButton;
        private static Button _resolveButton;
        private static Box _manifestInfo;
        private static Label _manifestLabel;
        private static Label _manifestInfoText;
        private static VisualElement _manifestPackageList;
        private static bool _isUpdating;
        private static Color _colorPositive = Color.green;
        private static Color _colorNegative = new Color(1, 0.3f, 0.3f);
        
        const string HAS_REFRESHED_KEY = "VRC.PackageManagement.Resolver.Refreshed";

        private static bool IsUpdating
        {
            get => _isUpdating;
            set
            {
                _isUpdating = value;
                _refreshButton.SetEnabled(!value);
                _refreshButton.text = value ? "Refreshing..." : "Refresh";
                _manifestLabel.text = value ? "Refreshing packages ..." : "Required Packages";
            }
        }


        [MenuItem("VRChat SDK/Utilities/Package Resolver")]
        public static void ShowWindow()
        {
            ResolverWindow wnd = GetWindow<ResolverWindow>();
            wnd.titleContent = new GUIContent("Package Resolver");
        }

        public static async Task Refresh()
        {
            if (_rootView == null || string.IsNullOrWhiteSpace(Resolver.ProjectDir)) return;

            IsUpdating = true;
            _manifestPackageList.Clear();
            
            // check for vpm dependencies
            if (!Resolver.VPMManifestExists())
            {
                _manifestInfoText.style.display = DisplayStyle.Flex;
                _manifestInfoText.text = "No VPM Manifest";
                _manifestInfoText.style.color = _colorNegative;
            }
            else
            {
                _manifestInfoText.style.display = DisplayStyle.None;
            }
            
            var manifest = VPMProjectManifest.Load(Resolver.ProjectDir);
            var project = await Task.Run(() => new UnityProject(Resolver.ProjectDir));
            
            // Here is where we detect if all dependencies are installed
            var allDependencies = manifest.locked != null && manifest.locked.Count > 0
                ? manifest.locked
                : manifest.dependencies;

            var depList = await Task.Run(() =>
            {
                var results = new Dictionary<(string id, string version), (IVRCPackage package, List<string> allVersions)>();
                foreach (var pair in allDependencies)
                {
                    var id = pair.Key;
                    var version = pair.Value.version;
                    var package = project.VPMProvider.GetPackage(id, version);
                    results.Add((id, version), (package, Resolver.GetAllVersionsOf(id)));
                }

                var legacyPackages = project.VPMProvider.GetLegacyPackages();

                results = results.Where(i => !legacyPackages.Contains(i.Key.id)).ToDictionary(i => i.Key, i => i.Value);

                return results;
            });
            
            foreach (var dep in depList)
            {
                
                _manifestPackageList.Add(
                    CreateDependencyRow(
                        dep.Key.id, 
                        dep.Key.version, 
                        project, 
                        dep.Value.package,
                        dep.Value.allVersions
                    )
                );
            }

            IsUpdating = false;
        }

        /// <summary>
        /// Unity calls the CreateGUI method automatically when the window needs to display
        /// </summary>
        private void CreateGUI()
        {
            ScrollView scrollView = new ScrollView()
            {
                horizontalScrollerVisibility = ScrollerVisibility.Hidden,
            };
            rootVisualElement.Add(scrollView);
            
            _rootView = scrollView;
            _rootView.name = "root-view";
            _rootView.styleSheets.Add((StyleSheet)Resources.Load("ResolverWindowStyle"));

            // Main Container
            var container = new Box()
            {
                name = "buttons"
            };
            _rootView.Add(container);

            // Create Button
            if (!Resolver.VPMManifestExists())
            {
                _createButton = new Button(Resolver.CreateManifest)
                {
                    text = "Create",
                    name = "create-button-base"
                };
                container.Add(_createButton);
            }
            else
            {
                _resolveButton = new Button(Resolver.ResolveManifest)
                {
                    text = "Resolve All",
                    name = "resolve-button-base"
                };
                container.Add(_resolveButton);
            }

            // Manifest Info
            _manifestInfo = new Box()
            {
                name = "manifest-info",
            };
            _manifestLabel = (new Label("Required Packages") { name = "manifest-header" });
            _manifestInfo.Add(_manifestLabel);
            _manifestInfoText = new Label();
            _manifestInfo.Add(_manifestInfoText);
            _manifestPackageList = new ScrollView()
            {
                verticalScrollerVisibility = ScrollerVisibility.Hidden,
            };
            _manifestPackageList.style.flexDirection = FlexDirection.Column;
            _manifestPackageList.style.alignItems = Align.Stretch;
            _manifestInfo.Add(_manifestPackageList);

            _rootView.Add(_manifestInfo);

            // Refresh Button
            var refreshBox = new Box();
            _refreshButton = new Button(() =>
            {
                // When manually refreshing - ensure package manager is also up to date
                Resolver.ForceRefresh();
                Refresh().ConfigureAwait(false);
            })
            {
                text = "Refresh",
                name = "refresh-button-base"
            };
            refreshBox.Add(_refreshButton);
            _rootView.Add(refreshBox);
            
            // Refresh on open
            // Sometimes unity can get into a bad state where calling package manager refresh will endlessly reload assemblies
            // That in turn means that a Full refresh will be called every single time assemblies are loaded
            // Which locks up the editor in an endless loop
            // This condition ensures that the UPM resolve only happens on first launch
            // We also call it after installing packages or hitting Refresh manually
            if (!SessionState.GetBool(HAS_REFRESHED_KEY, false))
            {
                SessionState.SetBool(HAS_REFRESHED_KEY, true);
                Resolver.ForceRefresh();
            }

            rootVisualElement.schedule.Execute(() => Refresh().ConfigureAwait(false)).ExecuteLater(100);
        }

        private static VisualElement CreateDependencyRow(string id, string version, UnityProject project, IVRCPackage package, List <string> allVersions)
        {
            bool havePackage = package != null;
            
            // Table Row
            VisualElement row = new Box { name = "package-row" };
            VisualElement column1 = new Box { name = "package-box" };
            VisualElement column2 = new Box { name = "package-box" };
            VisualElement column3 = new Box { name = "package-box" };
            VisualElement column4 = new Box { name = "package-box" };

            column1.style.minWidth = 200;
            column1.style.width = new StyleLength(new Length(40, LengthUnit.Percent));
            column2.style.minWidth = 100;
            column2.style.width = new StyleLength(new Length(19f, LengthUnit.Percent));
            column3.style.minWidth = 100;
            column3.style.width = new StyleLength(new Length(19f, LengthUnit.Percent));
            column4.style.minWidth = 100;
            column4.style.width = new StyleLength(new Length(19f, LengthUnit.Percent));

            row.Add(column1);
            row.Add(column2);
            row.Add(column3);
            row.Add(column4);

            // Package Name + Status
            column1.style.alignItems = Align.FlexStart;
            if (havePackage)
            {
                column1.style.flexDirection = FlexDirection.Column;
                var titleRow = new VisualElement();
                titleRow.style.unityFontStyleAndWeight = FontStyle.Bold;
                titleRow.Add(new Label(package.Title));
                column1.Add(titleRow);
            }
            TextElement text = new TextElement { text = $"{id} {version} " };

            column1.Add(text);

            if (!havePackage)
            {
                TextElement missingText = new TextElement { text = "MISSING" };
                missingText.style.color = _colorNegative;
                column2.Add(missingText);
            }

            // Version Popup
            var currVersion = Mathf.Max(0, havePackage ? allVersions.IndexOf(package.Version) : 0);
            var popupField = new PopupField<string>(allVersions, 0)
            {
                value = allVersions[currVersion],
                style = { flexGrow = 1}
            };

            column3.Add(popupField);

            // Button

            Button updateButton = new Button() { text = "Update" };
            if (havePackage)
                RefreshUpdateButton(updateButton, version, allVersions[0]);
            else
                RefreshMissingButton(updateButton);

            updateButton.clicked += (() =>
            {
                IVRCPackage package = Repos.GetPackageWithVersionMatch(id, popupField.value);

                // Check and warn on Dependencies if Updating or Downgrading
                if (Version.TryParse(version, out var currentVersion) &&
                    Version.TryParse(popupField.value, out var newVersion))
                {
                    Dictionary<string, string> dependencies = new Dictionary<string, string>();
                    StringBuilder dialogMsg = new StringBuilder();
                    List<string> affectedPackages = Resolver.GetAffectedPackageList(package);
                    for (int v = 0; v < affectedPackages.Count; v++)
                    {
                        dialogMsg.Append(affectedPackages[v]);
                    }

                    if (affectedPackages.Count > 1)
                    {
                        dialogMsg.Insert(0, "This will update multiple packages:\n\n");
                        dialogMsg.AppendLine("\nAre you sure?");
                        if (EditorUtility.DisplayDialog("Package Has Dependencies", dialogMsg.ToString(), "OK", "Cancel"))
                            OnUpdatePackageClicked(project, package);
                    }
                    else
                    {
                        OnUpdatePackageClicked(project, package);
                    }
                }

            });
            column4.Add(updateButton);

            popupField.RegisterCallback<ChangeEvent<string>>((evt) =>
            {
                if (havePackage)
                    RefreshUpdateButton(updateButton, version, evt.newValue);
                else
                    RefreshMissingButton(updateButton);
            });

            return row;
        }

        private static void RefreshUpdateButton(Button button, string currentVersion, string highestAvailableVersion)
        {
            if (currentVersion == highestAvailableVersion)
            {
                button.style.display = DisplayStyle.None;
            }
            else
            {
                button.style.display = (_isUpdating ? DisplayStyle.None : DisplayStyle.Flex);
                if (Version.TryParse(currentVersion, out var currentVersionObject) &&
                    Version.TryParse(highestAvailableVersion, out var highestAvailableVersionObject))
                {
                    if (currentVersionObject < highestAvailableVersionObject)
                    {
                        SetButtonColor(button, _colorPositive);
                        button.text = "Update";
                    }
                    else
                    {
                        SetButtonColor(button, _colorNegative);
                        button.text = "Downgrade";
                    }
                }
            }
        }

        private static void RefreshMissingButton(Button button)
        {
            button.text = "Resolve";
            SetButtonColor(button, Color.white);
        }

        private static void SetButtonColor(Button button, Color color)
        {
            button.style.color = color;
            color.a = 0.25f;
            button.style.borderRightColor =
            button.style.borderLeftColor =
            button.style.borderTopColor =
            button.style.borderBottomColor =
            color;
        }

        private static async void OnUpdatePackageClicked(UnityProject project, IVRCPackage package)
        {
            _isUpdating = true;
            await Refresh();
            await Task.Delay(500);
            project.UpdateVPMPackage(package);
            _isUpdating = false;
            await Refresh();
            Resolver.ForceRefresh();
        }

    }
}