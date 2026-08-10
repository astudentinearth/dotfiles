import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import Workspaces from "./Workspaces";




export default function Bar(gdkmonitor: Gdk.Monitor) {
    const time = createPoll("", 1000, () => new Date().toLocaleTimeString())
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor


    return (
        <window
            visible
            name="bar"
            class="Bar"
            gdkmonitor={gdkmonitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={TOP | LEFT | RIGHT}
            application={app}
        >
            <centerbox cssName="centerbox">
                <Workspaces />
                <menubutton $type="end" css_classes={["clock-btn"]} halign={Gtk.Align.END}>
                    <label label={time} />
                    <popover hasArrow={false} css_classes={["calendar-popover"]}>
                        <box css="border-radius: 16px;" orientation={Gtk.Orientation.VERTICAL}>
                            <label hexpand halign={Gtk.Align.START} label={time} css="font-size: 24px; margin: 8px 12px;" />
                            <Gtk.Calendar />
                        </box>
                    </popover>
                </menubutton>
            </centerbox>
        </window>
    )
}
