module ViVa

using DataFrames
#using PlotlyJS
#using Rsvg
#using Blink
using GeneticVariation
using ArgParse
using VCFTools
using RCall
#using Base.Filesystem

#include("vcf_utils.jl")
#include("plot_utils.jl")

#end #module

#=
const g_white = "400" #homo reference 0/0
const g_red = "800" #homo variant 1/1 1/2 2/2 1/3 2/3 3/3 4/4 5/5 6/6 etc
const g_pink = "600" #hetero variant 0/1 1/0 0/2 2/0 etc
const g_blue = "0" #no call ./.
=#

export
    format_reader,
    load_vcf,
    clean_column1!,
    genotype_cell_searcher_maf_correction,
    genotype_cell_searcher,
    dp_cell_searcher,
    load_siglist,
    sig_list_vcf_filter,
    chromosome_range_vcf_filter,
    load_sort_phenotype_matrix,
    reorder_columns,
    select_columns,
    genotype_heatmap2,
    dp_heatmap2,
    avg_sample_dp_scatter,
    avg_variant_dp_line_chart,
    read_depth_threshhold,
    list_variant_positions_low_dp,
    list_sample_names_low_dp,
    avg_dp_variant,
    avg_dp_samples,
    jupyter_main,
    save_numerical_array,
    io_pass_filter,
    io_sig_list_vcf_filter,
    io_chromosome_range_vcf_filter,
    generate_genotype_array,
    define_geno_dict,
    translate_genotype_to_num_array,
    translate_readdepth_strings_to_num_array,
    genotype_heatmap_with_groups,
    jupyter_main_new,
    returnXY_column1!,
    pass_chrrange_siglist_filter,
    pass_chrrange_filter,
    pass_siglist_filter,
    chrrange_siglist_filter,
    get_sample_names,
    sortcols_by_phenotype_matrix,
    find_group_label_indices,
    checkfor_outputdirectory,
    combined_all_genotype_array_functions,
    combined_all_read_depth_array_functions,
    generate_chromosome_positions_for_hover_labels,
    clean_column1_chr,
    clean_column1_siglist!,
    process_plot_inputs,
    process_plot_inputs_for_grouped_data,
    returnXY_column1_siglist!

#include("vcf_utils.jl")
include("vcf_utils_complete.jl")
include("plot_utils.jl")
#include("notebook_utils.jl")
include("new_notebook_utils.jl")
#include("io_filters.jl")

end # module
