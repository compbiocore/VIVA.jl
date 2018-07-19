#guide for writing technical docs - https://software.broadinstitute.org/gatk/documentation/tooldocs/3.8-0/org_broadinstitute_gatk_tools_walkers_variantutils_VariantsToTable.php

# *** Outline of program: ***

#A.) load and clean VCF

             #1) determine row number of header line to avoid "##" in META intro lines, read vcf file, clean and order in ascending chr position order
             #2) data cleaning

#B) define all functions

        #1) field selection

              #a) FORMAT reader - get index of fields to visualize
              #b) maf match list for maf correction of genotype
              #c) genotype selection with maf correction of genotype
              #d) genotype selection with no maf correction
              #e) read depth selection

        #2) variant selection

              #a) siglist match filter
              #b) match chromosome range filter
              #c) rare variants only

        #3) rearrange and select columns

              #a) rearrange columns by phenotype with use input phenotype matrix
              #b) select columns to visualize

        #4) plotting functions

              #a) define plotlyJS function for genotype heatmap
              #b) define plotlyJS function for read depth heatmap

#C) run functions for every possible combination of features

        #1) universal filters

               #a) PASS FILTER variants only
               #b) reorder columns to match list
               #c) select columns to visualize

        #2) combinations of field selection and variant selection filters

               #a) genotype / display all variants
               #b) genotype / select variants matching significant variant location list
               #c) genotype / select variants within chromosomal range
               #d) read depth / display all variants
               #e) read depth / select variants matching significant variant location list
               #f) read depth / select variants within chromosomal range

# *** End of outline ***

using DataFrames #use CSV.jl ? depwarnings
using CSV
using PlotlyJS
using Rsvg
using Blink
using ViVa
#=
const g_white = 400 #homo reference 0/0
const g_red = 800 #homo variant 1/1 1/2 2/2 1/3 2/3 3/3 4/4 5/5 6/6 etc
const g_pink = 600 #hetero variant 0/1 1/0 0/2 2/0 etc
const g_blue = 0 #no call ./.
=#
"""
    main(ARGS::Vector{String})
"""
function main()

#=
    #A.) load and clean VCF
    readvcf = readlines(ARGS[1])

    for row = 1:size(readvcf,1)

        if contains(readvcf[row], "#CHROM")
            header_col = row
            global header_col
            header_string = readvcf[row]
        end
    end

    skipstart_number=header_col-1 #this allows vcf to be loaded by readtable, the META lines at beginning of file start with "##" and interfere with readtable function - need readtable vs readdlm for reorder columns
    #df_vcf=readtable(ARGS[1], skipstart=skipstart_number, separator='\t')

    #create dataframe with CSV.jl
    df_vcf = CSV.read(ARGS[1], delim="\t", datarow = header_col+1, categorical=false, header = header_col, types=Dict(1=>String))

    vcf=Matrix(df_vcf)

    #cf=Matrix(df_vcf)

    #load vcf as dataframe twice: once to use for matrix and other to pull header info from

    #df_vcf=readtable(ARGS[1], skipstart=skipstart_number, separator='\t')

    #2) data cleaning
    ViVa.clean_column1!(vcf)

    for n = 1:size(vcf,1)
        #if typeof(vcf) == "String"
        if vcf[n, 1] != 23 && vcf[n, 1] != 24
        vcf[n, 1] = parse(Int64, vcf[n, 1])
        end
    #end
    end

    #sort rows by chr then chromosome position so are in order of chromosomal architecture
    vcf = sortrows(vcf, by=x->(x[1],x[2]))

    vcf = load_vcf(ARGS[1])


=#
    #=convert dataframe to matrix - must modify promote_rule to fix ambiguity in Missings in CategoricalArrays
    function tryeval1()
               @eval newfun2() = Base.promote_rule(::Type{C}, ::Type{Any}) where {C <: CategoricalArrays.CatValue} = Any
               Base.invokelatest(newfun2)
           end
           tryeval1()
=#

records = nrecords(vcf_file)
samples = nsamples(vcf_file)
println("VCF file contains $records variant records across $samples samples")

vcf_tuple = ViVa.load_vcf(ARGS[1])
original_vcf = vcf_tuple[1]
df_vcf = vcf_tuple[2]

vcf = original_vcf

index = ViVa.format_reader(vcf, ARGS[3])

#retain original version of vcf for second run


    #1) field selection

    #a) FORMAT reader - get index of fields to visualize

    #what features to visualize from INFO field - or others - if FORMAT / genotype info isn't included
    #index other data per variant for bars
    #check if format col is included, if so - run function, if not are there cells for each sample? I don't think so - check this.
    global index = format_reader(vcf,ARGS[3])

    #type_index = typeof(index)
    #println("This is the index: $index it is $type_index type.")

    #C) Run functions for every possible combination of features

    #1) universal filters

    #a) PASS FILTER variants only

    if ARGS[5] == "pass_only"
        vcf=vcf[(vcf[:,7].== "PASS"),:]
    end

    #b) reorder columns to match list

    if ARGS[6] == "reorder_columns"
        #vcf = reorder_columns(ARGS[7])
        vcf = ViVa.load_sort_phenotype_matrix(ARGS[7], ARGS[11], vcf, df_vcf)
    end

    #c) select columns to visualize

    if ARGS[9] == "select_columns"
        vcf = ViVa.select_columns(ARGS[10], vcf, df_vcf)
    end

    #2) combinations of field selection and variant selection filters
    #a) genotype / display all variants

    if ARGS[3] == "genotype" && ARGS[4] == "all"

        #replace cells of vcf file with representative values for field chosen (genotype value)
        vcf = ViVa.genotype_cell_searcher(vcf,index)

        println(typeof(vcf[2,40]))

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=vcf[:,10:size(vcf,2)]

        #define title for plot
        if ARGS[5] == "pass_only"
            title = "Genotype Data for All Pass Variants"
        else
            title = "Genotype Data for All Variants"
        end


        #plot heatmap for genotype and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.genotype_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[2] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "all_genotype.$extension")

        #=activate this block if want to export labeled value matrix for internal team use

        #df_withsamplenames=readtable(ARGS[1], skipstart=skipstart_number, header=false,separator='\t')
        df_withsamplenames = CSV.read(vcf_filename, delim="\t", datarow = header_col+1, header = false, types=Dict(1=>String))

        Base.promote_rule(::Type{C}, ::Type{Any}) where {C <: CategoricalArrays.CatValue} = Any
        vcf=Matrix(df_withsamplenames)

        samplenames=df_withsamplenames[1,10:size(df_withsamplenames,2)]
        samplenames=Matrix(samplenames)
        #chr_heading = "chr"
        #pos_heading = "position"
        headings = hcat("chr","position")
        samplenames = hcat(headings,samplenames)
        chrlabels=vcf[:,1:2]

        chr_labeled_array_for_plotly=hcat(chrlabels, array_for_plotly)
        labeled_value_matrix_withsamplenames= vcat(samplenames,chr_labeled_array_for_plotly)

        writedlm("labeled_value_matrix.txt", labeled_value_matrix_withsamplenames, "\t")
=#

    elseif ARGS[3] == "genotype" && ARGS[4] == "list"
        #df1=DataFrame(vcf)

        #load siglist file
        siglist_unsorted=readdlm(ARGS[8], ',',skipstart=1)

        #replace X with 23 and sort by chr# and position
        ViVa.clean_column1!(siglist_unsorted)
        siglist=sortrows(siglist_unsorted, by=x->(x[1],x[2]))

        #significant variants only filter - subarray of vcf matching lsit of variants of interest
        vcf = ViVa.sig_list_vcf_filter(vcf,siglist)

        #write over vcf to create value matrix for genotype fieldtype
        sig_list_subarray_post=ViVa.genotype_cell_searcher(vcf,index)

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=sig_list_subarray_post[:,10:size(sig_list_subarray_post,2)]
        title = "Genotype Data for Variants of Interest"

        #plot heatmap for genotype and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.genotype_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[5] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "siglist_genotype.$extension")

    elseif ARGS[3] == "genotype" && ARGS[4] == "range"

        #define range of variants to visualize
        chr_range = ARGS[8]

        #create subarray of vcf matching range parameters
        chr_range_subarray_pre = ViVa.chromosome_range_vcf_filter(chr_range,vcf)

        #write over vcf to create keyed-values matrix showing genotype
        chr_range_subarray_post = ViVa.genotype_cell_searcher(chr_range_subarray_pre,index)

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=chr_range_subarray_post[:,10:size(chr_range_subarray_post,2)]

        chrlabels=chr_range_subarray_post[:,1:2]
        chr_labeled_array_for_plotly=hcat(chrlabels, array_for_plotly)      #array for R_translation
        writedlm("labeled_value_matrix_chr_range.txt", chr_labeled_array_for_plotly, "\t")

        #define title
        title = "Genotype Data for Variants within $(ARGS[8])"

        #plot heatmap for genotype and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.genotype_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[2] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "chr_range_genotype.$extension")

    elseif ARGS[3] == "read_depth" && ARGS[4] == "all"

        #replace cells of vcf file with representative values for field chosen (genotype value)
        vcf = ViVa.dp_cell_searcher(vcf,index)

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=vcf[:,10:size(vcf,2)]

        #define title for plot

        if ARGS[5] == "pass_only"
            title = "Read Depth Data for All Pass Variants"
        else
            title = "Read Depth Data for All Variants"
        end


        #plot heatmap for genotype and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.dp_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[2] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "all_readdepth.$extension")

        #=***
        activate this block if want to export labeled value matrix for internal team use

        df_withsamplenames=readtable(ARGS[1], skipstart=skipstart_number, header=false,separator='\t')
        samplenames=df_withsamplenames[1,10:size(df_withsamplenames,2)]
        samplenames=Matrix(samplenames)
        chrlabels=vcf[:,1:2]

        chr_labeled_array_for_plotly=hcat(chrlabels, array_for_plotly)
        labeled_value_matrix_withsamplenames= vcat(samplenames,chr_labeled_array_for_plotly)

        writedlm("labeled_value_matrix.txt", labeled_value_matrix_withsamplenames, "\t")
        ***=#

    elseif ARGS[3] == "read_depth" && ARGS[4] == "list"

        #load siglist file
        siglist_unsorted=readdlm(ARGS[8], ',',skipstart=1)

        #replace X with 23 and sort by chr# and position
        ViVa.clean_column1!(siglist_unsorted)
        siglist=sortrows(siglist_unsorted, by=x->(x[1],x[2]))

        #create subarray of vcf per siglist
        vcf = ViVa.sig_list_vcf_filter(vcf, siglist)

        #write over vcf to create keyed-values matrix showing genotype
        sig_list_subarray_post=ViVa.dp_cell_searcher(vcf,index)

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=sig_list_subarray_post[:,10:size(sig_list_subarray_post,2)]
        title = "Read Depth Data for Variants of Interest"

        #plot heatmap for read depth and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.dp_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[2] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "siglist_readdepth.$extension")

    elseif ARGS[3] == "read_depth" && ARGS[4] == "range"

        #define range of variants to visualize
        chr_range = ARGS[8]

        #create subarray of vcf matching range parameters
        chr_range_subarray_pre = ViVa.chromosome_range_vcf_filter(chr_range,vcf)

        #write over vcf to create keyed-values matrix showing genotype
        chr_range_subarray_post = ViVa.dp_cell_searcher(chr_range_subarray_pre,index)

        #convert value overwritten vcf into subarray of just values, no annotation/meta info
        array_for_plotly=chr_range_subarray_post[:,10:size(chr_range_subarray_post,2)]

        #define title
        title = "Read Depth Data for Variants within $(ARGS[8])"

        #plot heatmap for read depth and save as format specified by ARGS[2], defaults to pdf
        graphic = ViVa.dp_heatmap2(array_for_plotly,title)
        extension=ARGS[2] #must define this variable, if use ARGS[5] directly in savefig it is read as String[pdf] or something instead of just "pdf"
        PlotlyJS.savefig(graphic, "chr_range_readdepth.$extension")

        #Conditional Genotype quality (GQ) ex. 12

        #Phred-scaled genotype likelihood (PL) ex. 79

        #RMS mapping quality (MQ)


    end
end


main()
