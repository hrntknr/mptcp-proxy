; ModuleID = 'mptcp_server_kern.c'
source_filename = "mptcp_server_kern.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.bpf_map_def = type { i32, i32, i32, i32, i32 }
%struct.xdp_md = type { i32, i32, i32, i32, i32 }
%struct.ethhdr = type { [6 x i8], [6 x i8], i16 }
%struct.ip6_hdr = type { %union.anon, %struct.in6_addr, %struct.in6_addr }
%union.anon = type { %struct.ip6_hdrctl }
%struct.ip6_hdrctl = type { i32, i16, i8, i8 }
%struct.in6_addr = type { %union.anon.0 }
%union.anon.0 = type { [4 x i32] }

@new_session = dso_local global %struct.bpf_map_def { i32 4, i32 4, i32 4, i32 1, i32 0 }, section "maps", align 4, !dbg !0
@_license = dso_local global [4 x i8] c"GPL\00", section "license", align 1, !dbg !135
@llvm.used = appending global [3 x i8*] [i8* getelementptr inbounds ([4 x i8], [4 x i8]* @_license, i32 0, i32 0), i8* bitcast (i32 (%struct.xdp_md*)* @mptcp_server to i8*), i8* bitcast (%struct.bpf_map_def* @new_session to i8*)], section "llvm.metadata"

; Function Attrs: nounwind uwtable
define dso_local i32 @mptcp_server(%struct.xdp_md* nocapture readonly %0) #0 section "xdp" !dbg !159 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !172, metadata !DIExpression()), !dbg !173
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !174, metadata !DIExpression()) #3, !dbg !180
  %3 = getelementptr inbounds %struct.xdp_md, %struct.xdp_md* %0, i64 0, i32 1, !dbg !182
  %4 = load i32, i32* %3, align 4, !dbg !182, !tbaa !183
  %5 = zext i32 %4 to i64, !dbg !188
  %6 = inttoptr i64 %5 to i8*, !dbg !189
  call void @llvm.dbg.value(metadata i8* %6, metadata !177, metadata !DIExpression()) #3, !dbg !180
  %7 = getelementptr inbounds %struct.xdp_md, %struct.xdp_md* %0, i64 0, i32 0, !dbg !190
  %8 = load i32, i32* %7, align 4, !dbg !190, !tbaa !191
  %9 = zext i32 %8 to i64, !dbg !192
  %10 = inttoptr i64 %9 to %struct.ethhdr*, !dbg !193
  call void @llvm.dbg.value(metadata %struct.ethhdr* %10, metadata !178, metadata !DIExpression()) #3, !dbg !180
  call void @llvm.dbg.value(metadata %struct.ethhdr* %10, metadata !179, metadata !DIExpression()) #3, !dbg !180
  %11 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 0, !dbg !194
  %12 = icmp ugt i8* %11, %6, !dbg !194
  br i1 %12, label %264, label %13, !dbg !196

13:                                               ; preds = %1
  %14 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 0, i32 2, !dbg !197
  %15 = load i16, i16* %14, align 1, !dbg !197, !tbaa !199
  %16 = icmp eq i16 %15, -8826, !dbg !202
  br i1 %16, label %17, label %264, !dbg !203

17:                                               ; preds = %13
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !204, metadata !DIExpression()) #3, !dbg !213
  call void @llvm.dbg.value(metadata i8* %11, metadata !209, metadata !DIExpression()) #3, !dbg !213
  call void @llvm.dbg.value(metadata %struct.ethhdr* undef, metadata !210, metadata !DIExpression()) #3, !dbg !213
  call void @llvm.dbg.value(metadata i8* %6, metadata !211, metadata !DIExpression()) #3, !dbg !213
  call void @llvm.dbg.value(metadata i8* %11, metadata !212, metadata !DIExpression()) #3, !dbg !213
  %18 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 40, !dbg !215
  %19 = icmp ugt i8* %18, %6, !dbg !215
  br i1 %19, label %264, label %20, !dbg !217

20:                                               ; preds = %17
  call void @llvm.dbg.value(metadata i8* %11, metadata !212, metadata !DIExpression()) #3, !dbg !213
  %21 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 6, !dbg !218
  %22 = load i8, i8* %21, align 2, !dbg !218, !tbaa !220
  %23 = icmp eq i8 %22, 41, !dbg !221
  br i1 %23, label %24, label %264, !dbg !222

24:                                               ; preds = %20
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !223, metadata !DIExpression()) #3, !dbg !233
  call void @llvm.dbg.value(metadata i8* %18, metadata !228, metadata !DIExpression()) #3, !dbg !233
  call void @llvm.dbg.value(metadata %struct.ethhdr* undef, metadata !229, metadata !DIExpression()) #3, !dbg !233
  call void @llvm.dbg.value(metadata %struct.ip6_hdr* undef, metadata !230, metadata !DIExpression()) #3, !dbg !233
  call void @llvm.dbg.value(metadata i8* %6, metadata !231, metadata !DIExpression()) #3, !dbg !233
  call void @llvm.dbg.value(metadata i8* %18, metadata !232, metadata !DIExpression()) #3, !dbg !233
  %25 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 80, !dbg !235
  %26 = icmp ugt i8* %25, %6, !dbg !235
  br i1 %26, label %264, label %27, !dbg !237

27:                                               ; preds = %24
  call void @llvm.dbg.value(metadata i8* %18, metadata !232, metadata !DIExpression()) #3, !dbg !233
  %28 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 46, !dbg !238
  %29 = load i8, i8* %28, align 2, !dbg !238, !tbaa !220
  %30 = icmp eq i8 %29, 6, !dbg !240
  br i1 %30, label %31, label %264, !dbg !241

31:                                               ; preds = %27
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !242, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata i8* %25, metadata !247, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata %struct.ethhdr* undef, metadata !248, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata %struct.ip6_hdr* undef, metadata !249, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata %struct.ip6_hdr* undef, metadata !250, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata i8* %6, metadata !251, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata i8* %25, metadata !252, metadata !DIExpression()) #3, !dbg !253
  %32 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 100, !dbg !255
  %33 = icmp ugt i8* %32, %6, !dbg !255
  br i1 %33, label %264, label %34, !dbg !257

34:                                               ; preds = %31
  call void @llvm.dbg.value(metadata i8* %25, metadata !252, metadata !DIExpression()) #3, !dbg !253
  call void @llvm.dbg.value(metadata %struct.xdp_md* %0, metadata !258, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8* %32, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata %struct.ethhdr* undef, metadata !264, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata %struct.ip6_hdr* undef, metadata !265, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata %struct.ip6_hdr* undef, metadata !266, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8* %25, metadata !267, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8* %6, metadata !268, metadata !DIExpression()) #3, !dbg !284
  %35 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 92, !dbg !286
  %36 = bitcast i8* %35 to i16*, !dbg !286
  %37 = load i16, i16* %36, align 4, !dbg !286
  %38 = lshr i16 %37, 2, !dbg !287
  %39 = and i16 %38, 60, !dbg !287
  %40 = zext i16 %39 to i64, !dbg !288
  call void @llvm.dbg.value(metadata i16 %39, metadata !269, metadata !DIExpression(DW_OP_constu, 20, DW_OP_minus, DW_OP_stack_value)) #3, !dbg !284
  %41 = getelementptr i8, i8* %25, i64 %40, !dbg !289
  call void @llvm.dbg.value(metadata i8* %41, metadata !270, metadata !DIExpression()) #3, !dbg !284
  %42 = icmp ugt i8* %41, %6, !dbg !290
  br i1 %42, label %264, label %43, !dbg !292

43:                                               ; preds = %34
  call void @llvm.dbg.value(metadata i8 0, metadata !275, metadata !DIExpression()) #3, !dbg !293
  call void @llvm.dbg.value(metadata i8* %32, metadata !263, metadata !DIExpression()) #3, !dbg !284
  %44 = getelementptr %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 101, !dbg !294
  %45 = icmp ugt i8* %44, %41, !dbg !296
  %46 = icmp ugt i8* %44, %6, !dbg !297
  %47 = or i1 %46, %45, !dbg !299
  br i1 %47, label %264, label %48, !dbg !299

48:                                               ; preds = %43
  %49 = load i8, i8* %32, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %49, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %49, label %50 [
    i8 0, label %264
    i8 1, label %81
  ], !dbg !301

50:                                               ; preds = %48
  %51 = getelementptr %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 102, !dbg !302
  %52 = icmp ugt i8* %51, %6, !dbg !304
  br i1 %52, label %264, label %53, !dbg !305

53:                                               ; preds = %50
  %54 = load i8, i8* %44, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %54, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %55 = icmp ult i8 %54, 2, !dbg !307
  br i1 %55, label %264, label %56, !dbg !309

56:                                               ; preds = %53
  %57 = zext i8 %54 to i64, !dbg !310
  %58 = getelementptr i8, i8* %32, i64 %57, !dbg !310
  %59 = icmp ugt i8* %58, %6, !dbg !312
  br i1 %59, label %264, label %60, !dbg !313

60:                                               ; preds = %56
  %61 = icmp eq i8 %49, 30, !dbg !314
  br i1 %61, label %62, label %81, !dbg !315

62:                                               ; preds = %60
  %63 = getelementptr %struct.ethhdr, %struct.ethhdr* %10, i64 1, i32 0, i64 103, !dbg !316
  %64 = icmp ugt i8* %63, %6, !dbg !318
  br i1 %64, label %264, label %65, !dbg !319

65:                                               ; preds = %62
  %66 = load i8, i8* %51, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %66, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %67 = icmp ult i8 %66, 16, !dbg !321
  br i1 %67, label %68, label %81, !dbg !321

68:                                               ; preds = %261, %234, %208, %182, %156, %130, %104, %65
  %69 = phi i8* [ %32, %65 ], [ %82, %104 ], [ %108, %130 ], [ %134, %156 ], [ %160, %182 ], [ %186, %208 ], [ %212, %234 ], [ %238, %261 ]
  %70 = phi i8 [ %54, %65 ], [ %93, %104 ], [ %119, %130 ], [ %145, %156 ], [ %171, %182 ], [ %197, %208 ], [ %223, %234 ], [ %250, %261 ], !dbg !306
  call void @llvm.dbg.value(metadata i8* %69, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8* %69, metadata !263, metadata !DIExpression()) #3, !dbg !284
  %71 = icmp eq i8 %70, 20, !dbg !322
  br i1 %71, label %72, label %264, !dbg !324

72:                                               ; preds = %68
  %73 = getelementptr i8, i8* %69, i64 20, !dbg !325
  %74 = icmp ugt i8* %73, %6, !dbg !327
  br i1 %74, label %264, label %75, !dbg !328

75:                                               ; preds = %72
  %76 = getelementptr i8, i8* %69, i64 4, !dbg !329
  %77 = bitcast i8* %76 to i64*, !dbg !330
  %78 = load i64, i64* %77, align 8, !dbg !331, !tbaa !332
  call void @llvm.dbg.value(metadata i64 %78, metadata !271, metadata !DIExpression()) #3, !dbg !284
  %79 = bitcast i32* %2 to i8*, !dbg !334
  call void @llvm.lifetime.start.p0i8(i64 4, i8* nonnull %79) #3, !dbg !334
  call void @llvm.dbg.value(metadata i32 680997, metadata !277, metadata !DIExpression()) #3, !dbg !335
  store i32 680997, i32* %2, align 4, !dbg !334
  call void @llvm.dbg.value(metadata i32* %2, metadata !277, metadata !DIExpression(DW_OP_deref)) #3, !dbg !335
  %80 = call i64 (i8*, i32, ...) inttoptr (i64 6 to i64 (i8*, i32, ...)*)(i8* nonnull %79, i32 4, i64 %78) #3, !dbg !334
  call void @llvm.lifetime.end.p0i8(i64 4, i8* nonnull %79) #3, !dbg !336
  br label %264, !dbg !337

81:                                               ; preds = %65, %60, %48
  %82 = phi i8* [ %58, %65 ], [ %58, %60 ], [ %44, %48 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %82, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 1, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %83 = getelementptr i8, i8* %82, i64 1, !dbg !294
  %84 = icmp ugt i8* %83, %41, !dbg !296
  %85 = icmp ugt i8* %83, %6, !dbg !297
  %86 = or i1 %84, %85, !dbg !299
  br i1 %86, label %264, label %87, !dbg !299

87:                                               ; preds = %81
  %88 = load i8, i8* %82, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %88, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %88, label %89 [
    i8 0, label %264
    i8 1, label %107
  ], !dbg !301

89:                                               ; preds = %87
  %90 = getelementptr i8, i8* %82, i64 2, !dbg !302
  %91 = icmp ugt i8* %90, %6, !dbg !304
  br i1 %91, label %264, label %92, !dbg !305

92:                                               ; preds = %89
  %93 = load i8, i8* %83, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %93, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %94 = icmp ult i8 %93, 2, !dbg !307
  br i1 %94, label %264, label %95, !dbg !309

95:                                               ; preds = %92
  %96 = zext i8 %93 to i64, !dbg !310
  %97 = getelementptr i8, i8* %82, i64 %96, !dbg !310
  %98 = icmp ugt i8* %97, %6, !dbg !312
  br i1 %98, label %264, label %99, !dbg !313

99:                                               ; preds = %95
  %100 = icmp eq i8 %88, 30, !dbg !314
  br i1 %100, label %101, label %107, !dbg !315

101:                                              ; preds = %99
  %102 = getelementptr i8, i8* %82, i64 3, !dbg !316
  %103 = icmp ugt i8* %102, %6, !dbg !318
  br i1 %103, label %264, label %104, !dbg !319

104:                                              ; preds = %101
  %105 = load i8, i8* %90, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %105, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %106 = icmp ult i8 %105, 16, !dbg !321
  br i1 %106, label %68, label %107, !dbg !321

107:                                              ; preds = %104, %99, %87
  %108 = phi i8* [ %97, %104 ], [ %97, %99 ], [ %83, %87 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %108, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 2, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %109 = getelementptr i8, i8* %108, i64 1, !dbg !294
  %110 = icmp ugt i8* %109, %41, !dbg !296
  %111 = icmp ugt i8* %109, %6, !dbg !297
  %112 = or i1 %110, %111, !dbg !299
  br i1 %112, label %264, label %113, !dbg !299

113:                                              ; preds = %107
  %114 = load i8, i8* %108, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %114, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %114, label %115 [
    i8 0, label %264
    i8 1, label %133
  ], !dbg !301

115:                                              ; preds = %113
  %116 = getelementptr i8, i8* %108, i64 2, !dbg !302
  %117 = icmp ugt i8* %116, %6, !dbg !304
  br i1 %117, label %264, label %118, !dbg !305

118:                                              ; preds = %115
  %119 = load i8, i8* %109, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %119, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %120 = icmp ult i8 %119, 2, !dbg !307
  br i1 %120, label %264, label %121, !dbg !309

121:                                              ; preds = %118
  %122 = zext i8 %119 to i64, !dbg !310
  %123 = getelementptr i8, i8* %108, i64 %122, !dbg !310
  %124 = icmp ugt i8* %123, %6, !dbg !312
  br i1 %124, label %264, label %125, !dbg !313

125:                                              ; preds = %121
  %126 = icmp eq i8 %114, 30, !dbg !314
  br i1 %126, label %127, label %133, !dbg !315

127:                                              ; preds = %125
  %128 = getelementptr i8, i8* %108, i64 3, !dbg !316
  %129 = icmp ugt i8* %128, %6, !dbg !318
  br i1 %129, label %264, label %130, !dbg !319

130:                                              ; preds = %127
  %131 = load i8, i8* %116, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %131, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %132 = icmp ult i8 %131, 16, !dbg !321
  br i1 %132, label %68, label %133, !dbg !321

133:                                              ; preds = %130, %125, %113
  %134 = phi i8* [ %123, %130 ], [ %123, %125 ], [ %109, %113 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %134, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 3, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %135 = getelementptr i8, i8* %134, i64 1, !dbg !294
  %136 = icmp ugt i8* %135, %41, !dbg !296
  %137 = icmp ugt i8* %135, %6, !dbg !297
  %138 = or i1 %136, %137, !dbg !299
  br i1 %138, label %264, label %139, !dbg !299

139:                                              ; preds = %133
  %140 = load i8, i8* %134, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %140, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %140, label %141 [
    i8 0, label %264
    i8 1, label %159
  ], !dbg !301

141:                                              ; preds = %139
  %142 = getelementptr i8, i8* %134, i64 2, !dbg !302
  %143 = icmp ugt i8* %142, %6, !dbg !304
  br i1 %143, label %264, label %144, !dbg !305

144:                                              ; preds = %141
  %145 = load i8, i8* %135, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %145, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %146 = icmp ult i8 %145, 2, !dbg !307
  br i1 %146, label %264, label %147, !dbg !309

147:                                              ; preds = %144
  %148 = zext i8 %145 to i64, !dbg !310
  %149 = getelementptr i8, i8* %134, i64 %148, !dbg !310
  %150 = icmp ugt i8* %149, %6, !dbg !312
  br i1 %150, label %264, label %151, !dbg !313

151:                                              ; preds = %147
  %152 = icmp eq i8 %140, 30, !dbg !314
  br i1 %152, label %153, label %159, !dbg !315

153:                                              ; preds = %151
  %154 = getelementptr i8, i8* %134, i64 3, !dbg !316
  %155 = icmp ugt i8* %154, %6, !dbg !318
  br i1 %155, label %264, label %156, !dbg !319

156:                                              ; preds = %153
  %157 = load i8, i8* %142, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %157, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %158 = icmp ult i8 %157, 16, !dbg !321
  br i1 %158, label %68, label %159, !dbg !321

159:                                              ; preds = %156, %151, %139
  %160 = phi i8* [ %149, %156 ], [ %149, %151 ], [ %135, %139 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %160, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 4, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %161 = getelementptr i8, i8* %160, i64 1, !dbg !294
  %162 = icmp ugt i8* %161, %41, !dbg !296
  %163 = icmp ugt i8* %161, %6, !dbg !297
  %164 = or i1 %162, %163, !dbg !299
  br i1 %164, label %264, label %165, !dbg !299

165:                                              ; preds = %159
  %166 = load i8, i8* %160, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %166, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %166, label %167 [
    i8 0, label %264
    i8 1, label %185
  ], !dbg !301

167:                                              ; preds = %165
  %168 = getelementptr i8, i8* %160, i64 2, !dbg !302
  %169 = icmp ugt i8* %168, %6, !dbg !304
  br i1 %169, label %264, label %170, !dbg !305

170:                                              ; preds = %167
  %171 = load i8, i8* %161, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %171, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %172 = icmp ult i8 %171, 2, !dbg !307
  br i1 %172, label %264, label %173, !dbg !309

173:                                              ; preds = %170
  %174 = zext i8 %171 to i64, !dbg !310
  %175 = getelementptr i8, i8* %160, i64 %174, !dbg !310
  %176 = icmp ugt i8* %175, %6, !dbg !312
  br i1 %176, label %264, label %177, !dbg !313

177:                                              ; preds = %173
  %178 = icmp eq i8 %166, 30, !dbg !314
  br i1 %178, label %179, label %185, !dbg !315

179:                                              ; preds = %177
  %180 = getelementptr i8, i8* %160, i64 3, !dbg !316
  %181 = icmp ugt i8* %180, %6, !dbg !318
  br i1 %181, label %264, label %182, !dbg !319

182:                                              ; preds = %179
  %183 = load i8, i8* %168, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %183, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %184 = icmp ult i8 %183, 16, !dbg !321
  br i1 %184, label %68, label %185, !dbg !321

185:                                              ; preds = %182, %177, %165
  %186 = phi i8* [ %175, %182 ], [ %175, %177 ], [ %161, %165 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %186, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 5, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %187 = getelementptr i8, i8* %186, i64 1, !dbg !294
  %188 = icmp ugt i8* %187, %41, !dbg !296
  %189 = icmp ugt i8* %187, %6, !dbg !297
  %190 = or i1 %188, %189, !dbg !299
  br i1 %190, label %264, label %191, !dbg !299

191:                                              ; preds = %185
  %192 = load i8, i8* %186, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %192, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %192, label %193 [
    i8 0, label %264
    i8 1, label %211
  ], !dbg !301

193:                                              ; preds = %191
  %194 = getelementptr i8, i8* %186, i64 2, !dbg !302
  %195 = icmp ugt i8* %194, %6, !dbg !304
  br i1 %195, label %264, label %196, !dbg !305

196:                                              ; preds = %193
  %197 = load i8, i8* %187, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %197, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %198 = icmp ult i8 %197, 2, !dbg !307
  br i1 %198, label %264, label %199, !dbg !309

199:                                              ; preds = %196
  %200 = zext i8 %197 to i64, !dbg !310
  %201 = getelementptr i8, i8* %186, i64 %200, !dbg !310
  %202 = icmp ugt i8* %201, %6, !dbg !312
  br i1 %202, label %264, label %203, !dbg !313

203:                                              ; preds = %199
  %204 = icmp eq i8 %192, 30, !dbg !314
  br i1 %204, label %205, label %211, !dbg !315

205:                                              ; preds = %203
  %206 = getelementptr i8, i8* %186, i64 3, !dbg !316
  %207 = icmp ugt i8* %206, %6, !dbg !318
  br i1 %207, label %264, label %208, !dbg !319

208:                                              ; preds = %205
  %209 = load i8, i8* %194, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %209, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %210 = icmp ult i8 %209, 16, !dbg !321
  br i1 %210, label %68, label %211, !dbg !321

211:                                              ; preds = %208, %203, %191
  %212 = phi i8* [ %201, %208 ], [ %201, %203 ], [ %187, %191 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %212, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 6, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %213 = getelementptr i8, i8* %212, i64 1, !dbg !294
  %214 = icmp ugt i8* %213, %41, !dbg !296
  %215 = icmp ugt i8* %213, %6, !dbg !297
  %216 = or i1 %214, %215, !dbg !299
  br i1 %216, label %264, label %217, !dbg !299

217:                                              ; preds = %211
  %218 = load i8, i8* %212, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %218, metadata !272, metadata !DIExpression()) #3, !dbg !284
  switch i8 %218, label %219 [
    i8 0, label %264
    i8 1, label %237
  ], !dbg !301

219:                                              ; preds = %217
  %220 = getelementptr i8, i8* %212, i64 2, !dbg !302
  %221 = icmp ugt i8* %220, %6, !dbg !304
  br i1 %221, label %264, label %222, !dbg !305

222:                                              ; preds = %219
  %223 = load i8, i8* %213, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %223, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %224 = icmp ult i8 %223, 2, !dbg !307
  br i1 %224, label %264, label %225, !dbg !309

225:                                              ; preds = %222
  %226 = zext i8 %223 to i64, !dbg !310
  %227 = getelementptr i8, i8* %212, i64 %226, !dbg !310
  %228 = icmp ugt i8* %227, %6, !dbg !312
  br i1 %228, label %264, label %229, !dbg !313

229:                                              ; preds = %225
  %230 = icmp eq i8 %218, 30, !dbg !314
  br i1 %230, label %231, label %237, !dbg !315

231:                                              ; preds = %229
  %232 = getelementptr i8, i8* %212, i64 3, !dbg !316
  %233 = icmp ugt i8* %232, %6, !dbg !318
  br i1 %233, label %264, label %234, !dbg !319

234:                                              ; preds = %231
  %235 = load i8, i8* %220, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %235, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %236 = icmp ult i8 %235, 16, !dbg !321
  br i1 %236, label %68, label %237, !dbg !321

237:                                              ; preds = %234, %229, %217
  %238 = phi i8* [ %227, %234 ], [ %227, %229 ], [ %213, %217 ], !dbg !338
  call void @llvm.dbg.value(metadata i8* %238, metadata !263, metadata !DIExpression()) #3, !dbg !284
  call void @llvm.dbg.value(metadata i8 7, metadata !275, metadata !DIExpression()) #3, !dbg !293
  %239 = getelementptr i8, i8* %238, i64 1, !dbg !294
  %240 = icmp ugt i8* %239, %41, !dbg !296
  %241 = icmp ugt i8* %239, %6, !dbg !297
  %242 = or i1 %240, %241, !dbg !299
  br i1 %242, label %264, label %243, !dbg !299

243:                                              ; preds = %237
  %244 = load i8, i8* %238, align 1, !dbg !300, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %244, metadata !272, metadata !DIExpression()) #3, !dbg !284
  %245 = icmp ult i8 %244, 2, !dbg !301
  br i1 %245, label %264, label %246, !dbg !301

246:                                              ; preds = %243
  %247 = getelementptr i8, i8* %238, i64 2, !dbg !302
  %248 = icmp ugt i8* %247, %6, !dbg !304
  br i1 %248, label %264, label %249, !dbg !305

249:                                              ; preds = %246
  %250 = load i8, i8* %239, align 1, !dbg !306, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %250, metadata !273, metadata !DIExpression()) #3, !dbg !284
  %251 = icmp ult i8 %250, 2, !dbg !307
  br i1 %251, label %264, label %252, !dbg !309

252:                                              ; preds = %249
  %253 = zext i8 %250 to i64, !dbg !310
  %254 = getelementptr i8, i8* %238, i64 %253, !dbg !310
  %255 = icmp ugt i8* %254, %6, !dbg !312
  br i1 %255, label %264, label %256, !dbg !313

256:                                              ; preds = %252
  %257 = icmp eq i8 %244, 30, !dbg !314
  br i1 %257, label %258, label %264, !dbg !315

258:                                              ; preds = %256
  %259 = getelementptr i8, i8* %238, i64 3, !dbg !316
  %260 = icmp ugt i8* %259, %6, !dbg !318
  br i1 %260, label %264, label %261, !dbg !319

261:                                              ; preds = %258
  %262 = load i8, i8* %247, align 1, !dbg !320, !tbaa !220
  call void @llvm.dbg.value(metadata i8 %262, metadata !274, metadata !DIExpression(DW_OP_constu, 4, DW_OP_shr, DW_OP_stack_value)) #3, !dbg !284
  %263 = icmp ult i8 %262, 16, !dbg !321
  br i1 %263, label %68, label %264, !dbg !321

264:                                              ; preds = %1, %13, %17, %20, %24, %27, %31, %34, %43, %48, %50, %53, %56, %62, %68, %72, %75, %81, %87, %89, %92, %95, %101, %107, %113, %115, %118, %121, %127, %133, %139, %141, %144, %147, %153, %159, %165, %167, %170, %173, %179, %185, %191, %193, %196, %199, %205, %211, %217, %219, %222, %225, %231, %237, %243, %246, %249, %252, %256, %258, %261
  %265 = phi i32 [ 1, %1 ], [ 2, %13 ], [ 1, %17 ], [ 2, %20 ], [ 1, %24 ], [ 2, %27 ], [ 1, %31 ], [ 1, %72 ], [ 2, %68 ], [ 2, %75 ], [ 1, %34 ], [ 2, %43 ], [ 2, %48 ], [ 1, %62 ], [ 1, %56 ], [ 1, %53 ], [ 1, %50 ], [ 2, %81 ], [ 2, %87 ], [ 1, %89 ], [ 1, %92 ], [ 1, %95 ], [ 1, %101 ], [ 2, %107 ], [ 2, %113 ], [ 1, %115 ], [ 1, %118 ], [ 1, %121 ], [ 1, %127 ], [ 2, %133 ], [ 2, %139 ], [ 1, %141 ], [ 1, %144 ], [ 1, %147 ], [ 1, %153 ], [ 2, %159 ], [ 2, %165 ], [ 1, %167 ], [ 1, %170 ], [ 1, %173 ], [ 1, %179 ], [ 2, %185 ], [ 2, %191 ], [ 1, %193 ], [ 1, %196 ], [ 1, %199 ], [ 1, %205 ], [ 2, %211 ], [ 2, %217 ], [ 1, %219 ], [ 1, %222 ], [ 1, %225 ], [ 1, %231 ], [ 2, %237 ], [ 1, %246 ], [ 1, %249 ], [ 1, %252 ], [ 1, %258 ], [ 2, %261 ], [ 2, %256 ], [ 2, %243 ], !dbg !180
  ret i32 %265, !dbg !339
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind willreturn }
attributes #2 = { nounwind readnone speculatable willreturn }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!155, !156, !157}
!llvm.ident = !{!158}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "new_session", scope: !2, file: !3, line: 13, type: !147, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 10.0.0-4ubuntu1 ", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, retainedTypes: !43, globals: !134, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "mptcp_server_kern.c", directory: "/home/hrntknr/work/go/src/github.com/hrntknr/mptcp-proxy/server")
!4 = !{!5, !14}
!5 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "xdp_action", file: !6, line: 3150, baseType: !7, size: 32, elements: !8)
!6 = !DIFile(filename: "/usr/include/linux/bpf.h", directory: "")
!7 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!8 = !{!9, !10, !11, !12, !13}
!9 = !DIEnumerator(name: "XDP_ABORTED", value: 0, isUnsigned: true)
!10 = !DIEnumerator(name: "XDP_DROP", value: 1, isUnsigned: true)
!11 = !DIEnumerator(name: "XDP_PASS", value: 2, isUnsigned: true)
!12 = !DIEnumerator(name: "XDP_TX", value: 3, isUnsigned: true)
!13 = !DIEnumerator(name: "XDP_REDIRECT", value: 4, isUnsigned: true)
!14 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !15, line: 40, baseType: !7, size: 32, elements: !16)
!15 = !DIFile(filename: "/usr/include/netinet/in.h", directory: "")
!16 = !{!17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35, !36, !37, !38, !39, !40, !41, !42}
!17 = !DIEnumerator(name: "IPPROTO_IP", value: 0, isUnsigned: true)
!18 = !DIEnumerator(name: "IPPROTO_ICMP", value: 1, isUnsigned: true)
!19 = !DIEnumerator(name: "IPPROTO_IGMP", value: 2, isUnsigned: true)
!20 = !DIEnumerator(name: "IPPROTO_IPIP", value: 4, isUnsigned: true)
!21 = !DIEnumerator(name: "IPPROTO_TCP", value: 6, isUnsigned: true)
!22 = !DIEnumerator(name: "IPPROTO_EGP", value: 8, isUnsigned: true)
!23 = !DIEnumerator(name: "IPPROTO_PUP", value: 12, isUnsigned: true)
!24 = !DIEnumerator(name: "IPPROTO_UDP", value: 17, isUnsigned: true)
!25 = !DIEnumerator(name: "IPPROTO_IDP", value: 22, isUnsigned: true)
!26 = !DIEnumerator(name: "IPPROTO_TP", value: 29, isUnsigned: true)
!27 = !DIEnumerator(name: "IPPROTO_DCCP", value: 33, isUnsigned: true)
!28 = !DIEnumerator(name: "IPPROTO_IPV6", value: 41, isUnsigned: true)
!29 = !DIEnumerator(name: "IPPROTO_RSVP", value: 46, isUnsigned: true)
!30 = !DIEnumerator(name: "IPPROTO_GRE", value: 47, isUnsigned: true)
!31 = !DIEnumerator(name: "IPPROTO_ESP", value: 50, isUnsigned: true)
!32 = !DIEnumerator(name: "IPPROTO_AH", value: 51, isUnsigned: true)
!33 = !DIEnumerator(name: "IPPROTO_MTP", value: 92, isUnsigned: true)
!34 = !DIEnumerator(name: "IPPROTO_BEETPH", value: 94, isUnsigned: true)
!35 = !DIEnumerator(name: "IPPROTO_ENCAP", value: 98, isUnsigned: true)
!36 = !DIEnumerator(name: "IPPROTO_PIM", value: 103, isUnsigned: true)
!37 = !DIEnumerator(name: "IPPROTO_COMP", value: 108, isUnsigned: true)
!38 = !DIEnumerator(name: "IPPROTO_SCTP", value: 132, isUnsigned: true)
!39 = !DIEnumerator(name: "IPPROTO_UDPLITE", value: 136, isUnsigned: true)
!40 = !DIEnumerator(name: "IPPROTO_MPLS", value: 137, isUnsigned: true)
!41 = !DIEnumerator(name: "IPPROTO_RAW", value: 255, isUnsigned: true)
!42 = !DIEnumerator(name: "IPPROTO_MAX", value: 256, isUnsigned: true)
!43 = !{!44, !45, !46, !59, !62, !108, !130, !131}
!44 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!45 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!46 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !47, size: 64)
!47 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "ethhdr", file: !48, line: 163, size: 112, elements: !49)
!48 = !DIFile(filename: "/usr/include/linux/if_ether.h", directory: "")
!49 = !{!50, !55, !56}
!50 = !DIDerivedType(tag: DW_TAG_member, name: "h_dest", scope: !47, file: !48, line: 164, baseType: !51, size: 48)
!51 = !DICompositeType(tag: DW_TAG_array_type, baseType: !52, size: 48, elements: !53)
!52 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!53 = !{!54}
!54 = !DISubrange(count: 6)
!55 = !DIDerivedType(tag: DW_TAG_member, name: "h_source", scope: !47, file: !48, line: 165, baseType: !51, size: 48, offset: 48)
!56 = !DIDerivedType(tag: DW_TAG_member, name: "h_proto", scope: !47, file: !48, line: 166, baseType: !57, size: 16, offset: 96)
!57 = !DIDerivedType(tag: DW_TAG_typedef, name: "__be16", file: !58, line: 25, baseType: !59)
!58 = !DIFile(filename: "/usr/include/linux/types.h", directory: "")
!59 = !DIDerivedType(tag: DW_TAG_typedef, name: "__u16", file: !60, line: 24, baseType: !61)
!60 = !DIFile(filename: "/usr/include/asm-generic/int-ll64.h", directory: "")
!61 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!62 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !63, size: 64)
!63 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "ip6_hdr", file: !64, line: 24, size: 320, elements: !65)
!64 = !DIFile(filename: "/usr/include/netinet/ip6.h", directory: "")
!65 = !{!66, !85, !107}
!66 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_ctlun", scope: !63, file: !64, line: 37, baseType: !67, size: 64)
!67 = distinct !DICompositeType(tag: DW_TAG_union_type, scope: !63, file: !64, line: 26, size: 64, elements: !68)
!68 = !{!69, !84}
!69 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un1", scope: !67, file: !64, line: 35, baseType: !70, size: 64)
!70 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "ip6_hdrctl", file: !64, line: 28, size: 64, elements: !71)
!71 = !{!72, !77, !80, !83}
!72 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un1_flow", scope: !70, file: !64, line: 30, baseType: !73, size: 32)
!73 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint32_t", file: !74, line: 26, baseType: !75)
!74 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdint-uintn.h", directory: "")
!75 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint32_t", file: !76, line: 42, baseType: !7)
!76 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "")
!77 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un1_plen", scope: !70, file: !64, line: 32, baseType: !78, size: 16, offset: 32)
!78 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint16_t", file: !74, line: 25, baseType: !79)
!79 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint16_t", file: !76, line: 40, baseType: !61)
!80 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un1_nxt", scope: !70, file: !64, line: 33, baseType: !81, size: 8, offset: 48)
!81 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint8_t", file: !74, line: 24, baseType: !82)
!82 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint8_t", file: !76, line: 38, baseType: !52)
!83 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un1_hlim", scope: !70, file: !64, line: 34, baseType: !81, size: 8, offset: 56)
!84 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_un2_vfc", scope: !67, file: !64, line: 36, baseType: !81, size: 8)
!85 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_src", scope: !63, file: !64, line: 38, baseType: !86, size: 128, offset: 64)
!86 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "in6_addr", file: !87, line: 33, size: 128, elements: !88)
!87 = !DIFile(filename: "/usr/include/linux/in6.h", directory: "")
!88 = !{!89}
!89 = !DIDerivedType(tag: DW_TAG_member, name: "in6_u", scope: !86, file: !87, line: 40, baseType: !90, size: 128)
!90 = distinct !DICompositeType(tag: DW_TAG_union_type, scope: !86, file: !87, line: 34, size: 128, elements: !91)
!91 = !{!92, !97, !101}
!92 = !DIDerivedType(tag: DW_TAG_member, name: "u6_addr8", scope: !90, file: !87, line: 35, baseType: !93, size: 128)
!93 = !DICompositeType(tag: DW_TAG_array_type, baseType: !94, size: 128, elements: !95)
!94 = !DIDerivedType(tag: DW_TAG_typedef, name: "__u8", file: !60, line: 21, baseType: !52)
!95 = !{!96}
!96 = !DISubrange(count: 16)
!97 = !DIDerivedType(tag: DW_TAG_member, name: "u6_addr16", scope: !90, file: !87, line: 37, baseType: !98, size: 128)
!98 = !DICompositeType(tag: DW_TAG_array_type, baseType: !57, size: 128, elements: !99)
!99 = !{!100}
!100 = !DISubrange(count: 8)
!101 = !DIDerivedType(tag: DW_TAG_member, name: "u6_addr32", scope: !90, file: !87, line: 38, baseType: !102, size: 128)
!102 = !DICompositeType(tag: DW_TAG_array_type, baseType: !103, size: 128, elements: !105)
!103 = !DIDerivedType(tag: DW_TAG_typedef, name: "__be32", file: !58, line: 27, baseType: !104)
!104 = !DIDerivedType(tag: DW_TAG_typedef, name: "__u32", file: !60, line: 27, baseType: !7)
!105 = !{!106}
!106 = !DISubrange(count: 4)
!107 = !DIDerivedType(tag: DW_TAG_member, name: "ip6_dst", scope: !63, file: !64, line: 39, baseType: !86, size: 128, offset: 192)
!108 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !109, size: 64)
!109 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "tcphdr", file: !110, line: 25, size: 160, elements: !111)
!110 = !DIFile(filename: "/usr/include/linux/tcp.h", directory: "")
!111 = !{!112, !113, !114, !115, !116, !117, !118, !119, !120, !121, !122, !123, !124, !125, !126, !127, !129}
!112 = !DIDerivedType(tag: DW_TAG_member, name: "source", scope: !109, file: !110, line: 26, baseType: !57, size: 16)
!113 = !DIDerivedType(tag: DW_TAG_member, name: "dest", scope: !109, file: !110, line: 27, baseType: !57, size: 16, offset: 16)
!114 = !DIDerivedType(tag: DW_TAG_member, name: "seq", scope: !109, file: !110, line: 28, baseType: !103, size: 32, offset: 32)
!115 = !DIDerivedType(tag: DW_TAG_member, name: "ack_seq", scope: !109, file: !110, line: 29, baseType: !103, size: 32, offset: 64)
!116 = !DIDerivedType(tag: DW_TAG_member, name: "res1", scope: !109, file: !110, line: 31, baseType: !59, size: 4, offset: 96, flags: DIFlagBitField, extraData: i64 96)
!117 = !DIDerivedType(tag: DW_TAG_member, name: "doff", scope: !109, file: !110, line: 32, baseType: !59, size: 4, offset: 100, flags: DIFlagBitField, extraData: i64 96)
!118 = !DIDerivedType(tag: DW_TAG_member, name: "fin", scope: !109, file: !110, line: 33, baseType: !59, size: 1, offset: 104, flags: DIFlagBitField, extraData: i64 96)
!119 = !DIDerivedType(tag: DW_TAG_member, name: "syn", scope: !109, file: !110, line: 34, baseType: !59, size: 1, offset: 105, flags: DIFlagBitField, extraData: i64 96)
!120 = !DIDerivedType(tag: DW_TAG_member, name: "rst", scope: !109, file: !110, line: 35, baseType: !59, size: 1, offset: 106, flags: DIFlagBitField, extraData: i64 96)
!121 = !DIDerivedType(tag: DW_TAG_member, name: "psh", scope: !109, file: !110, line: 36, baseType: !59, size: 1, offset: 107, flags: DIFlagBitField, extraData: i64 96)
!122 = !DIDerivedType(tag: DW_TAG_member, name: "ack", scope: !109, file: !110, line: 37, baseType: !59, size: 1, offset: 108, flags: DIFlagBitField, extraData: i64 96)
!123 = !DIDerivedType(tag: DW_TAG_member, name: "urg", scope: !109, file: !110, line: 38, baseType: !59, size: 1, offset: 109, flags: DIFlagBitField, extraData: i64 96)
!124 = !DIDerivedType(tag: DW_TAG_member, name: "ece", scope: !109, file: !110, line: 39, baseType: !59, size: 1, offset: 110, flags: DIFlagBitField, extraData: i64 96)
!125 = !DIDerivedType(tag: DW_TAG_member, name: "cwr", scope: !109, file: !110, line: 40, baseType: !59, size: 1, offset: 111, flags: DIFlagBitField, extraData: i64 96)
!126 = !DIDerivedType(tag: DW_TAG_member, name: "window", scope: !109, file: !110, line: 55, baseType: !57, size: 16, offset: 112)
!127 = !DIDerivedType(tag: DW_TAG_member, name: "check", scope: !109, file: !110, line: 56, baseType: !128, size: 16, offset: 128)
!128 = !DIDerivedType(tag: DW_TAG_typedef, name: "__sum16", file: !58, line: 31, baseType: !59)
!129 = !DIDerivedType(tag: DW_TAG_member, name: "urg_ptr", scope: !109, file: !110, line: 57, baseType: !57, size: 16, offset: 144)
!130 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !94, size: 64)
!131 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !132, size: 64)
!132 = !DIDerivedType(tag: DW_TAG_typedef, name: "__u64", file: !60, line: 31, baseType: !133)
!133 = !DIBasicType(name: "long long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!134 = !{!0, !135, !139}
!135 = !DIGlobalVariableExpression(var: !136, expr: !DIExpression())
!136 = distinct !DIGlobalVariable(name: "_license", scope: !2, file: !3, line: 142, type: !137, isLocal: false, isDefinition: true)
!137 = !DICompositeType(tag: DW_TAG_array_type, baseType: !138, size: 32, elements: !105)
!138 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!139 = !DIGlobalVariableExpression(var: !140, expr: !DIExpression())
!140 = distinct !DIGlobalVariable(name: "bpf_trace_printk", scope: !2, file: !141, line: 162, type: !142, isLocal: true, isDefinition: true)
!141 = !DIFile(filename: "../libbpf/src/bpf_helper_defs.h", directory: "/home/hrntknr/work/go/src/github.com/hrntknr/mptcp-proxy/server")
!142 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !143, size: 64)
!143 = !DISubroutineType(types: !144)
!144 = !{!45, !145, !104, null}
!145 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !146, size: 64)
!146 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !138)
!147 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "bpf_map_def", file: !148, line: 57, size: 160, elements: !149)
!148 = !DIFile(filename: "../libbpf/src/bpf_helpers.h", directory: "/home/hrntknr/work/go/src/github.com/hrntknr/mptcp-proxy/server")
!149 = !{!150, !151, !152, !153, !154}
!150 = !DIDerivedType(tag: DW_TAG_member, name: "type", scope: !147, file: !148, line: 58, baseType: !7, size: 32)
!151 = !DIDerivedType(tag: DW_TAG_member, name: "key_size", scope: !147, file: !148, line: 59, baseType: !7, size: 32, offset: 32)
!152 = !DIDerivedType(tag: DW_TAG_member, name: "value_size", scope: !147, file: !148, line: 60, baseType: !7, size: 32, offset: 64)
!153 = !DIDerivedType(tag: DW_TAG_member, name: "max_entries", scope: !147, file: !148, line: 61, baseType: !7, size: 32, offset: 96)
!154 = !DIDerivedType(tag: DW_TAG_member, name: "map_flags", scope: !147, file: !148, line: 62, baseType: !7, size: 32, offset: 128)
!155 = !{i32 7, !"Dwarf Version", i32 4}
!156 = !{i32 2, !"Debug Info Version", i32 3}
!157 = !{i32 1, !"wchar_size", i32 4}
!158 = !{!"clang version 10.0.0-4ubuntu1 "}
!159 = distinct !DISubprogram(name: "mptcp_server", scope: !3, file: !3, line: 137, type: !160, scopeLine: 138, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !171)
!160 = !DISubroutineType(types: !161)
!161 = !{!162, !163}
!162 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!163 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !164, size: 64)
!164 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "xdp_md", file: !6, line: 3161, size: 160, elements: !165)
!165 = !{!166, !167, !168, !169, !170}
!166 = !DIDerivedType(tag: DW_TAG_member, name: "data", scope: !164, file: !6, line: 3162, baseType: !104, size: 32)
!167 = !DIDerivedType(tag: DW_TAG_member, name: "data_end", scope: !164, file: !6, line: 3163, baseType: !104, size: 32, offset: 32)
!168 = !DIDerivedType(tag: DW_TAG_member, name: "data_meta", scope: !164, file: !6, line: 3164, baseType: !104, size: 32, offset: 64)
!169 = !DIDerivedType(tag: DW_TAG_member, name: "ingress_ifindex", scope: !164, file: !6, line: 3166, baseType: !104, size: 32, offset: 96)
!170 = !DIDerivedType(tag: DW_TAG_member, name: "rx_queue_index", scope: !164, file: !6, line: 3167, baseType: !104, size: 32, offset: 128)
!171 = !{!172}
!172 = !DILocalVariable(name: "ctx", arg: 1, scope: !159, file: !3, line: 137, type: !163)
!173 = !DILocation(line: 0, scope: !159)
!174 = !DILocalVariable(name: "ctx", arg: 1, scope: !175, file: !3, line: 122, type: !163)
!175 = distinct !DISubprogram(name: "process_ethhdr", scope: !3, file: !3, line: 122, type: !160, scopeLine: 123, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !176)
!176 = !{!174, !177, !178, !179}
!177 = !DILocalVariable(name: "data_end", scope: !175, file: !3, line: 124, type: !44)
!178 = !DILocalVariable(name: "data", scope: !175, file: !3, line: 125, type: !44)
!179 = !DILocalVariable(name: "eth", scope: !175, file: !3, line: 126, type: !46)
!180 = !DILocation(line: 0, scope: !175, inlinedAt: !181)
!181 = distinct !DILocation(line: 139, column: 12, scope: !159)
!182 = !DILocation(line: 124, column: 41, scope: !175, inlinedAt: !181)
!183 = !{!184, !185, i64 4}
!184 = !{!"xdp_md", !185, i64 0, !185, i64 4, !185, i64 8, !185, i64 12, !185, i64 16}
!185 = !{!"int", !186, i64 0}
!186 = !{!"omnipotent char", !187, i64 0}
!187 = !{!"Simple C/C++ TBAA"}
!188 = !DILocation(line: 124, column: 30, scope: !175, inlinedAt: !181)
!189 = !DILocation(line: 124, column: 22, scope: !175, inlinedAt: !181)
!190 = !DILocation(line: 125, column: 37, scope: !175, inlinedAt: !181)
!191 = !{!184, !185, i64 0}
!192 = !DILocation(line: 125, column: 26, scope: !175, inlinedAt: !181)
!193 = !DILocation(line: 126, column: 26, scope: !175, inlinedAt: !181)
!194 = !DILocation(line: 128, column: 5, scope: !195, inlinedAt: !181)
!195 = distinct !DILexicalBlock(scope: !175, file: !3, line: 128, column: 5)
!196 = !DILocation(line: 128, column: 5, scope: !175, inlinedAt: !181)
!197 = !DILocation(line: 130, column: 14, scope: !198, inlinedAt: !181)
!198 = distinct !DILexicalBlock(scope: !175, file: !3, line: 130, column: 9)
!199 = !{!200, !201, i64 12}
!200 = !{!"ethhdr", !186, i64 0, !186, i64 6, !201, i64 12}
!201 = !{!"short", !186, i64 0}
!202 = !DILocation(line: 130, column: 22, scope: !198, inlinedAt: !181)
!203 = !DILocation(line: 130, column: 9, scope: !175, inlinedAt: !181)
!204 = !DILocalVariable(name: "ctx", arg: 1, scope: !205, file: !3, line: 109, type: !163)
!205 = distinct !DISubprogram(name: "process_ip6ip6hdr", scope: !3, file: !3, line: 109, type: !206, scopeLine: 110, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !208)
!206 = !DISubroutineType(types: !207)
!207 = !{!162, !163, !44, !46}
!208 = !{!204, !209, !210, !211, !212}
!209 = !DILocalVariable(name: "nxt_ptr", arg: 2, scope: !205, file: !3, line: 109, type: !44)
!210 = !DILocalVariable(name: "eth", arg: 3, scope: !205, file: !3, line: 109, type: !46)
!211 = !DILocalVariable(name: "data_end", scope: !205, file: !3, line: 111, type: !44)
!212 = !DILocalVariable(name: "ip6ip6", scope: !205, file: !3, line: 112, type: !62)
!213 = !DILocation(line: 0, scope: !205, inlinedAt: !214)
!214 = distinct !DILocation(line: 133, column: 12, scope: !175, inlinedAt: !181)
!215 = !DILocation(line: 114, column: 5, scope: !216, inlinedAt: !214)
!216 = distinct !DILexicalBlock(scope: !205, file: !3, line: 114, column: 5)
!217 = !DILocation(line: 114, column: 5, scope: !205, inlinedAt: !214)
!218 = !DILocation(line: 116, column: 35, scope: !219, inlinedAt: !214)
!219 = distinct !DILexicalBlock(scope: !205, file: !3, line: 116, column: 9)
!220 = !{!186, !186, i64 0}
!221 = !DILocation(line: 116, column: 47, scope: !219, inlinedAt: !214)
!222 = !DILocation(line: 116, column: 9, scope: !205, inlinedAt: !214)
!223 = !DILocalVariable(name: "ctx", arg: 1, scope: !224, file: !3, line: 96, type: !163)
!224 = distinct !DISubprogram(name: "process_ip6hdr", scope: !3, file: !3, line: 96, type: !225, scopeLine: 97, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !227)
!225 = !DISubroutineType(types: !226)
!226 = !{!162, !163, !44, !46, !62}
!227 = !{!223, !228, !229, !230, !231, !232}
!228 = !DILocalVariable(name: "nxt_ptr", arg: 2, scope: !224, file: !3, line: 96, type: !44)
!229 = !DILocalVariable(name: "eth", arg: 3, scope: !224, file: !3, line: 96, type: !46)
!230 = !DILocalVariable(name: "ip6ip6", arg: 4, scope: !224, file: !3, line: 96, type: !62)
!231 = !DILocalVariable(name: "data_end", scope: !224, file: !3, line: 98, type: !44)
!232 = !DILocalVariable(name: "ip6", scope: !224, file: !3, line: 99, type: !62)
!233 = !DILocation(line: 0, scope: !224, inlinedAt: !234)
!234 = distinct !DILocation(line: 119, column: 12, scope: !205, inlinedAt: !214)
!235 = !DILocation(line: 101, column: 5, scope: !236, inlinedAt: !234)
!236 = distinct !DILexicalBlock(scope: !224, file: !3, line: 101, column: 5)
!237 = !DILocation(line: 101, column: 5, scope: !224, inlinedAt: !234)
!238 = !DILocation(line: 103, column: 32, scope: !239, inlinedAt: !234)
!239 = distinct !DILexicalBlock(scope: !224, file: !3, line: 103, column: 9)
!240 = !DILocation(line: 103, column: 44, scope: !239, inlinedAt: !234)
!241 = !DILocation(line: 103, column: 9, scope: !224, inlinedAt: !234)
!242 = !DILocalVariable(name: "ctx", arg: 1, scope: !243, file: !3, line: 86, type: !163)
!243 = distinct !DISubprogram(name: "process_tcphdr", scope: !3, file: !3, line: 86, type: !244, scopeLine: 87, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !246)
!244 = !DISubroutineType(types: !245)
!245 = !{!162, !163, !44, !46, !62, !62}
!246 = !{!242, !247, !248, !249, !250, !251, !252}
!247 = !DILocalVariable(name: "nxt_ptr", arg: 2, scope: !243, file: !3, line: 86, type: !44)
!248 = !DILocalVariable(name: "eth", arg: 3, scope: !243, file: !3, line: 86, type: !46)
!249 = !DILocalVariable(name: "ip6ip6", arg: 4, scope: !243, file: !3, line: 86, type: !62)
!250 = !DILocalVariable(name: "ip6", arg: 5, scope: !243, file: !3, line: 86, type: !62)
!251 = !DILocalVariable(name: "data_end", scope: !243, file: !3, line: 88, type: !44)
!252 = !DILocalVariable(name: "tcp", scope: !243, file: !3, line: 89, type: !108)
!253 = !DILocation(line: 0, scope: !243, inlinedAt: !254)
!254 = distinct !DILocation(line: 106, column: 12, scope: !224, inlinedAt: !234)
!255 = !DILocation(line: 91, column: 5, scope: !256, inlinedAt: !254)
!256 = distinct !DILexicalBlock(scope: !243, file: !3, line: 91, column: 5)
!257 = !DILocation(line: 91, column: 5, scope: !243, inlinedAt: !254)
!258 = !DILocalVariable(name: "ctx", arg: 1, scope: !259, file: !3, line: 20, type: !163)
!259 = distinct !DISubprogram(name: "process_tcpopt", scope: !3, file: !3, line: 20, type: !260, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !262)
!260 = !DISubroutineType(types: !261)
!261 = !{!162, !163, !44, !46, !62, !62, !108}
!262 = !{!258, !263, !264, !265, !266, !267, !268, !269, !270, !271, !272, !273, !274, !275, !277}
!263 = !DILocalVariable(name: "nxt_ptr", arg: 2, scope: !259, file: !3, line: 20, type: !44)
!264 = !DILocalVariable(name: "eth", arg: 3, scope: !259, file: !3, line: 20, type: !46)
!265 = !DILocalVariable(name: "ip6ip6", arg: 4, scope: !259, file: !3, line: 20, type: !62)
!266 = !DILocalVariable(name: "ip6", arg: 5, scope: !259, file: !3, line: 20, type: !62)
!267 = !DILocalVariable(name: "tcp", arg: 6, scope: !259, file: !3, line: 20, type: !108)
!268 = !DILocalVariable(name: "data_end", scope: !259, file: !3, line: 22, type: !44)
!269 = !DILocalVariable(name: "opt_len", scope: !259, file: !3, line: 24, type: !162)
!270 = !DILocalVariable(name: "opt_end", scope: !259, file: !3, line: 25, type: !44)
!271 = !DILocalVariable(name: "client_key", scope: !259, file: !3, line: 26, type: !132)
!272 = !DILocalVariable(name: "opcode", scope: !259, file: !3, line: 27, type: !94)
!273 = !DILocalVariable(name: "opsize", scope: !259, file: !3, line: 28, type: !94)
!274 = !DILocalVariable(name: "subtype", scope: !259, file: !3, line: 29, type: !94)
!275 = !DILocalVariable(name: "i", scope: !276, file: !3, line: 34, type: !94)
!276 = distinct !DILexicalBlock(scope: !259, file: !3, line: 34, column: 5)
!277 = !DILocalVariable(name: "____fmt", scope: !278, file: !3, line: 75, type: !137)
!278 = distinct !DILexicalBlock(scope: !279, file: !3, line: 75, column: 17)
!279 = distinct !DILexicalBlock(scope: !280, file: !3, line: 67, column: 13)
!280 = distinct !DILexicalBlock(scope: !281, file: !3, line: 62, column: 9)
!281 = distinct !DILexicalBlock(scope: !282, file: !3, line: 61, column: 13)
!282 = distinct !DILexicalBlock(scope: !283, file: !3, line: 35, column: 5)
!283 = distinct !DILexicalBlock(scope: !276, file: !3, line: 34, column: 5)
!284 = !DILocation(line: 0, scope: !259, inlinedAt: !285)
!285 = distinct !DILocation(line: 93, column: 12, scope: !243, inlinedAt: !254)
!286 = !DILocation(line: 24, column: 28, scope: !259, inlinedAt: !285)
!287 = !DILocation(line: 24, column: 21, scope: !259, inlinedAt: !285)
!288 = !DILocation(line: 24, column: 19, scope: !259, inlinedAt: !285)
!289 = !DILocation(line: 25, column: 29, scope: !259, inlinedAt: !285)
!290 = !DILocation(line: 31, column: 27, scope: !291, inlinedAt: !285)
!291 = distinct !DILexicalBlock(scope: !259, file: !3, line: 31, column: 9)
!292 = !DILocation(line: 31, column: 9, scope: !259, inlinedAt: !285)
!293 = !DILocation(line: 0, scope: !276, inlinedAt: !285)
!294 = !DILocation(line: 36, column: 21, scope: !295, inlinedAt: !285)
!295 = distinct !DILexicalBlock(scope: !282, file: !3, line: 36, column: 13)
!296 = !DILocation(line: 36, column: 25, scope: !295, inlinedAt: !285)
!297 = !DILocation(line: 39, column: 25, scope: !298, inlinedAt: !285)
!298 = distinct !DILexicalBlock(scope: !282, file: !3, line: 39, column: 13)
!299 = !DILocation(line: 36, column: 13, scope: !282, inlinedAt: !285)
!300 = !DILocation(line: 41, column: 18, scope: !282, inlinedAt: !285)
!301 = !DILocation(line: 43, column: 13, scope: !282, inlinedAt: !285)
!302 = !DILocation(line: 51, column: 21, scope: !303, inlinedAt: !285)
!303 = distinct !DILexicalBlock(scope: !282, file: !3, line: 51, column: 13)
!304 = !DILocation(line: 51, column: 25, scope: !303, inlinedAt: !285)
!305 = !DILocation(line: 51, column: 13, scope: !282, inlinedAt: !285)
!306 = !DILocation(line: 53, column: 18, scope: !282, inlinedAt: !285)
!307 = !DILocation(line: 55, column: 20, scope: !308, inlinedAt: !285)
!308 = distinct !DILexicalBlock(scope: !282, file: !3, line: 55, column: 13)
!309 = !DILocation(line: 55, column: 13, scope: !282, inlinedAt: !285)
!310 = !DILocation(line: 58, column: 21, scope: !311, inlinedAt: !285)
!311 = distinct !DILexicalBlock(scope: !282, file: !3, line: 58, column: 13)
!312 = !DILocation(line: 58, column: 30, scope: !311, inlinedAt: !285)
!313 = !DILocation(line: 58, column: 13, scope: !282, inlinedAt: !285)
!314 = !DILocation(line: 61, column: 20, scope: !281, inlinedAt: !285)
!315 = !DILocation(line: 61, column: 13, scope: !282, inlinedAt: !285)
!316 = !DILocation(line: 63, column: 25, scope: !317, inlinedAt: !285)
!317 = distinct !DILexicalBlock(scope: !280, file: !3, line: 63, column: 17)
!318 = !DILocation(line: 63, column: 29, scope: !317, inlinedAt: !285)
!319 = !DILocation(line: 63, column: 17, scope: !280, inlinedAt: !285)
!320 = !DILocation(line: 65, column: 23, scope: !280, inlinedAt: !285)
!321 = !DILocation(line: 66, column: 13, scope: !280, inlinedAt: !285)
!322 = !DILocation(line: 69, column: 28, scope: !323, inlinedAt: !285)
!323 = distinct !DILexicalBlock(scope: !279, file: !3, line: 69, column: 21)
!324 = !DILocation(line: 69, column: 21, scope: !279, inlinedAt: !285)
!325 = !DILocation(line: 71, column: 29, scope: !326, inlinedAt: !285)
!326 = distinct !DILexicalBlock(scope: !279, file: !3, line: 71, column: 21)
!327 = !DILocation(line: 71, column: 57, scope: !326, inlinedAt: !285)
!328 = !DILocation(line: 71, column: 21, scope: !279, inlinedAt: !285)
!329 = !DILocation(line: 74, column: 49, scope: !279, inlinedAt: !285)
!330 = !DILocation(line: 74, column: 31, scope: !279, inlinedAt: !285)
!331 = !DILocation(line: 74, column: 30, scope: !279, inlinedAt: !285)
!332 = !{!333, !333, i64 0}
!333 = !{!"long long", !186, i64 0}
!334 = !DILocation(line: 75, column: 17, scope: !278, inlinedAt: !285)
!335 = !DILocation(line: 0, scope: !278, inlinedAt: !285)
!336 = !DILocation(line: 75, column: 17, scope: !279, inlinedAt: !285)
!337 = !DILocation(line: 76, column: 17, scope: !279, inlinedAt: !285)
!338 = !DILocation(line: 0, scope: !282, inlinedAt: !285)
!339 = !DILocation(line: 139, column: 5, scope: !159)
