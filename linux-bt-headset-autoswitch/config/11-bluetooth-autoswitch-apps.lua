-- Thêm app vào danh sách tự chuyển tai nghe Bluetooth sang HFP (có mic) khi app mở mic.
-- Danh sách gốc ở /usr/share/wireplumber/policy.lua.d/10-default-policy.lua; file này chạy sau nó.
-- Tên lấy từ application.name của luồng thu (xem: pactl list source-outputs).
local extra = {
  "Claude", "ChatGPT", "Electron", "Slack", "Microsoft Teams",
  "teams-for-linux", "Discord", "WEBRTC VoiceEngine",
}
for _, name in ipairs(extra) do
  table.insert(bluetooth_policy.policy["media-role.applications"], name)
end
