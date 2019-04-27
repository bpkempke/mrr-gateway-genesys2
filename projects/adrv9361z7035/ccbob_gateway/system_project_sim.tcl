
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

adi_project_xilinx fmcomms2_genesys2
adi_project_files fmcomms2_genesys2 [list \
  "system_top.v" \
  "ddr3_model.sv" \
  "system_constr.xdc"\
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/genesys2/genesys2_system_constr.xdc" ]

add_files -fileset "sim_1" -norecurse "system_top_sim.v"
set_property top "sim_top" [get_filesets "sim_1"]

launch_simulation

