import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# Create figure
fig, ax = plt.subplots(figsize=(10,5))

# Host box
host_box = mpatches.FancyBboxPatch((0.05, 0.35), 0.25, 0.3,
                                   boxstyle="round,pad=0.1", fc="black", ec="white", lw=1.5)
ax.add_patch(host_box)
ax.text(0.175, 0.5, "Host\n192.168.155.254:5055", ha="center", va="center", color="white", fontsize=10, weight="bold")

# NAT box
nat_box = mpatches.FancyBboxPatch((0.4, 0.35), 0.2, 0.3,
                                  boxstyle="round,pad=0.1", fc="#333", ec="white", lw=1.5)
ax.add_patch(nat_box)
ax.text(0.5, 0.5, "Hyper-V NAT\n(CustomNAT_A)", ha="center", va="center", color="white", fontsize=9)

# Guest box
guest_box = mpatches.FancyBboxPatch((0.75, 0.35), 0.25, 0.3,
                                    boxstyle="round,pad=0.1", fc="black", ec="white", lw=1.5)
ax.add_patch(guest_box)
ax.text(0.875, 0.5, "Guest VM\n192.168.155.10:5389", ha="center", va="center", color="white", fontsize=10, weight="bold")

# Arrows
ax.annotate("", xy=(0.38, 0.5), xytext=(0.3, 0.5),
            arrowprops=dict(arrowstyle="->", lw=2, color="white"))
ax.annotate("", xy=(0.72, 0.5), xytext=(0.6, 0.5),
            arrowprops=dict(arrowstyle="->", lw=2, color="white"))

# Labels
ax.text(0.34, 0.55, "Port fwd 5055 → 5389", color="white", fontsize=8)
ax.text(0.62, 0.55, "LAN RDP", color="white", fontsize=8)

# Cleanup
ax.set_facecolor("black")
ax.set_xticks([])
ax.set_yticks([])
ax.set_xlim(0,1)
ax.set_ylim(0,1)
ax.axis("off")

# Save
plt.savefig("/mnt/data/hyperv_nat_rdp_flow.png", dpi=150, bbox_inches="tight")
plt.close()

"/mnt/data/hyperv_nat_rdp_flow.png"
