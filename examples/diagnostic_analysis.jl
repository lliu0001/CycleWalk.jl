# julia analysis.jl ../atlasDirectory ../diagnosticOutputDirectory subFolderDirector 
#atlas lives in ../atlasDirectory/subFolderDirector
#output of diagnostics will live in ../diagnosticOutputDirectory subFolderDirector 
atlasBaseDir, analysisBaseDir, specificPath = ARGS
function getAtlasFileNames(baseDir, path)
    files = [f for f in readdir(joinpath(baseDir, path)) 
             if occursin("json", f)]
    return files
end
files = getAtlasFileNames(atlasBaseDir, specificPath)
# files = ["ct_cycleWalk_v0p2_thread1_cyclewalkVSinternal_0.001_gamma0.1_iso0.1.jsonl.gz"]
# filters
# files = [f for f in files if occursin("cntyw100.0.jsonl", f)]
# files = [f for f in files if occursin("cntyw100.0", f)]

using Distributed 
addprocs(length(files))

@everywhere import Pkg
@everywhere push!(LOAD_PATH, "..");
@everywhere mapSamplerPath = joinpath("/Users/g/Projects/Districting/CodeBases/multiscalemapsampler-dev-lct")
@everywhere push!(LOAD_PATH, mapSamplerPath);
@everywhere using LiftedTreeWalk

@everywhere function write_districting_diagnostics(
    m::Map, 
    io::IO,
    prev_step::Int64, 
    cur_step::Int64;
    write_header=false
)
    diagnostics = sort([k for k in keys(m.data) if k[1] == '('])
    if length(diagnostics) == 0
        return
    end
    if write_header
        headers = [split(k[2:end-1], ",")[end] for k in diagnostics]
        headers = [["approxStep", "outputStep"]; headers]
        write(io, join(headers, ",")*"\n")
    end
    n = length(m.data[diagnostics[1]])
    scale = cur_step-prev_step
    steps = [k/(n+1)*scale + prev_step for k=1:n]
    for ii in 1:n
        vals = [m.data[diagnostics[jj]][ii] for jj=1:length(diagnostics)]
        vals = [[steps[ii], cur_step]; vals]
        write(io, join(vals, ",")*"\n")
    end
end

@everywhere function processAtlasDiagnostics(atlasName, args)
    atlasBaseDir, analysisBaseDir, specificPath = args
###############
    # create diagnostic output directory
    ext,fileDesc = LiftedTreeWalk.getFileExtension(atlasName)
    if ext == ".gz"
        _,fileDesc = LiftedTreeWalk.getFileExtension(fileDesc)
    end
    outfilePrefix=joinpath(analysisBaseDir, specificPath, fileDesc)
    mkpath(outfilePrefix)
    @show myid(), fileDesc
################
    # open atlas
    filePath = joinpath(atlasBaseDir, specificPath, atlasName)
    io=smartOpen(filePath, "r")
    atlas=openAtlas(io);
    # skipMap(atlas)
################
    # open diagnostic file
    f = joinpath(outfilePrefix,string(fileDesc, "_diagnostics.csv.gz"))
    diagnosticFile = smartOpen(f,"w")

################

    mapCount=1
    cur_step = 0

    eachLine=eachline(atlas.io)
    write_header = true
    try
        for (mind, nextLine) in enumerate(eachLine)
            m=parseBufferToMap(atlas,nextLine)
            prev_step = cur_step
            cur_step = parse(Int64, m.name[length("step")+1:end])
            write_districting_diagnostics(m, diagnosticFile, prev_step, cur_step; 
                                          write_header=write_header)
            write_header = false
        end
    catch
        @show "corrupt atlas", atlas
    end
    close(atlas)
    close(diagnosticFile)
end

@sync @distributed for ii = 1:length(workers())
    file = files[ii]
    args = [atlasBaseDir, analysisBaseDir, specificPath]
    processAtlasDiagnostics(file, args)
end


 
