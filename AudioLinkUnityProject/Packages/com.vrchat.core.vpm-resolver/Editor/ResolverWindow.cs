using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;
using VRC.PackageManagement.Core.Types;
using VRC.PackageManagement.Core.Types.Packages;

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
        private static TextElement _manifestReadout;

        [MenuItem("VRChat SDK/Utilities/Package Resolver")]
        public static void ShowWindow()
        {
            ResolverWindow wnd = GetWindow<ResolverWindow>();
            wnd.titleContent = new GUIContent("Package Resolver");
        }

        public static void Refresh()
        {
            if (_rootView == null || string.IsNullOrWhiteSpace(Resolver.ProjectDir)) return;

            bool needsResolve = VPMProjectManifest.ResolveIsNeeded(Resolver.ProjectDir);
            string resolveStatus = needsResolve ? "Please press  \"Resolve\" to Download them." : "All of them are in the project.";
            
            // check for vpm dependencies
            if (!Resolver.VPMManifestExists())
            {
                _manifestReadout.text = "No VPM Manifest";
            }
            else
            {
                var manifest = VPMProjectManifest.Load(Resolver.ProjectDir);
                var project = new UnityProject(Resolver.ProjectDir);
                StringBuilder readout = new StringBuilder();
                
                // Here is where we detect if all dependencies are installed
                var allDependencies = (manifest.locked != null && manifest.locked.Count > 0)
                    ? manifest.locked
                    : manifest.dependencies;
                
                foreach (var pair in allDependencies)
                {
                    var id = pair.Key;
                    var version = pair.Value.version;
                    if (project.VPMProvider.GetPackage(id, version) == null)
                    {
                        readout.AppendLine($"{id} {version}: MISSING");
                    }
                    else
                    {
                        readout.AppendLine($"{id} {version}: GOOD");
                    }
                }

                _manifestReadout.text = readout.ToString();

            }
            _resolveButton.SetEnabled(needsResolve);
        }

        /// <summary>
        /// Unity calls the CreateGUI method automatically when the window needs to display
        /// </summary>
        private void CreateGUI()
        {
            _rootView = rootVisualElement;
            _rootView.name = "root-view";
            _rootView.styleSheets.Add((StyleSheet) Resources.Load("ResolverWindowStyle"));

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
                    text = "Resolve",
                    name = "resolve-button-base"
                };
                container.Add(_resolveButton);
            }

            // Manifest Info
            _manifestInfo = new Box()
            {
                name = "manifest-info",
            };
            _manifestInfo.Add(new Label("Required Packages"){name = "manifest-header"});
            _manifestReadout = new TextElement();
            _manifestInfo.Add(_manifestReadout);
            
            _rootView.Add(_manifestInfo);
            
            // Refresh Button
            var refreshBox = new Box();
            _refreshButton = new Button(Refresh)
            {
                text = "Refresh",
                name = "refresh-button-base"
            };
            refreshBox.Add(_refreshButton);
            _rootView.Add(refreshBox);
            
            Refresh();
        }
    }

}