import Hyprland from "gi://AstalHyprland"
import { createBinding, For, With } from "ags";
import { Gtk } from "ags/gtk4";

const hyprland = Hyprland.get_default();
const focusedWorkspace = createBinding(hyprland, "focusedWorkspace");
const workspaces = createBinding(hyprland, "workspaces");
export default function Workspaces() {


    return (
        <box css_classes={["workspaces"]} $type="start" orientation={Gtk.Orientation.HORIZONTAL}>
            <label label={focusedWorkspace(w => w.name)} />
        </box>
    )
}
