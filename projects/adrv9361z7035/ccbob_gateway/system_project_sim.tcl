
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

set p_device "xc7z035ifbg676-2L"
adi_project_xilinx adrv9361z7035_ccbob_lvds
adi_project_files adrv9361z7035_ccbob_lvds [list \
  "ddr3_model.sv" \
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "../common/adrv9361z7035_constr.xdc" \
  "../common/adrv9361z7035_constr_lvds.xdc" \
  "../common/ccbob_constr.xdc" \
  "system_top.v" ]

add_files -fileset "sim_1" -norecurse "system_top_sim.v"
set_property top "sim_top" [get_filesets "sim_1"]

launch_simulation

