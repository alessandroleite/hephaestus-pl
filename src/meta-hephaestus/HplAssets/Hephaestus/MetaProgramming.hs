module HplAssets.Hephaestus.MetaProgramming where

import Language.Haskell.Syntax
import Data.Generics

-- ----------------------------------------------------------
-- Operators for Haskell program transformation
-- ----------------------------------------------------------

setModuleName :: String -> HsModule -> HsModule
setModuleName n 
              (HsModule _ (Module _) exportSpec importDecls decls) =	 
               HsModule noSrcLoc (Module n) exportSpec importDecls decls


addImportDecl_Old :: String -> HsModule -> HsModule
addImportDecl_Old n 
              (HsModule _ m exportSpec importDecls decls) =	 
               HsModule noSrcLoc m exportSpec importDecls' decls
 where
  importDecls' = importDecls ++
    [ HsImportDecl {
        importLoc = noSrcLoc,
        importModule = Module n, 
        importQualified = False,
        importAs = Nothing, 
        importSpecs = Nothing } ]
        
        
addImportDecl :: String -> HsModule -> HsModule
addImportDecl n 
              (HsModule _ m exportSpec importDecls decls) =	 
               HsModule noSrcLoc m exportSpec (importDecls1 ++ [importDecl] ++ importDecls2) decls
 where
  (importDecls1,importDecl,importDecls2) = findImportDecl n importDecls 
 
        
        
removeImportDecl :: String -> HsModule -> HsModule
removeImportDecl n 
              (HsModule _ m exportSpec importDecls decls) =	 
               HsModule noSrcLoc m exportSpec (importDecls1 ++ importDecls2) decls
 where
  (importDecls1,importDecl,importDecls2) = findImportDecl n importDecls 
        
        
-- find the import Module n. If do not find then insert it and return.        
findImportDecl :: String -> [HsImportDecl] -> ([HsImportDecl], HsImportDecl, [HsImportDecl])
findImportDecl n decls = findImportDecl' [] decls
 where
   findImportDecl' _ [] = (decls, (HsImportDecl noSrcLoc (Module n) False Nothing Nothing), []) -- error ("import " ++ n ++ " not found.")
   findImportDecl' decls1 (decl@(HsImportDecl noSrcLoc n' _ _ _):decls2)
     = if Module n == n'
	    then (decls1,decl,decls2) 
     else findImportDecl' (decls1 ++ [decl]) decls2
	    

addField :: String -> [(String, String)] -> HsModule -> HsModule
addField dataName [x]    = addField' dataName (fst x) (snd x)
addField dataName (x:xs) = addField' dataName (fst x) (snd x) . addField dataName xs

addField' :: String -> String -> String -> HsModule -> HsModule
addField' dataName fieldName typeName
         (HsModule _ m exportSpec importDecls decls) = 
          HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1,decl,decls2) = findDataDecl dataName "" decls
  fieldType = HsUnBangedTy (HsTyCon (UnQual (HsIdent typeName)))
  decl' = case decl of
            (HsDataDecl _ [] n [] [HsRecDecl _ n' fields] dis) ->
             let fields' = fields ++ [([HsIdent fieldName], fieldType)] in
              HsDataDecl noSrcLoc [] n [] [HsRecDecl noSrcLoc n' fields'] dis
            _ -> error ("Datatype " ++ dataName ++ " not suitable.")


--initializeFieldWithFun :: String -> String -> String ->  String -> HsModule -> HsModule
--initializeFieldWithFun dataName fieldName parmFun funName = everywhere (mkT initializeField')
-- where
--  initializeField' :: HsExp -> HsExp
--  initializeField' (HsRecConstr (UnQual (HsIdent n)) updates) | n == dataName && funName /= " " =
--                    HsRecConstr (UnQual (HsIdent n)) updates'
--   where
--    updates' = updates ++ [ HsFieldUpdate
--                              (UnQual (HsIdent fieldName))
--                              (HsApp (HsVar (UnQual (HsIdent funName))) (HsParen (HsApp (HsVar (UnQual (HsIdent parmFun))) (HsVar (UnQual (HsIdent "spl"))))))]
--  initializeField' x = x


initializeFieldWithFun :: String -> String -> String ->  String -> HsModule -> HsModule
initializeFieldWithFun dataName fieldName parmFun funName = everywhere (mkT initializeField')
 where
  initializeField' :: HsExp -> HsExp
  initializeField' (HsRecConstr (UnQual (HsIdent n)) updates) | n == dataName && funName /= "emptyCode" =
                    HsRecConstr (UnQual (HsIdent n)) updates'
   where
    updates' = updates ++ [ HsFieldUpdate
                              (UnQual (HsIdent fieldName))
                              (HsApp (HsVar (UnQual (HsIdent funName))) (HsParen (HsApp (HsVar (UnQual (HsIdent parmFun))) (HsVar (UnQual (HsIdent "spl"))))))]
  
  initializeField' (HsRecConstr (UnQual (HsIdent n)) updates) | n == dataName && funName == "emptyCode" =
                    HsRecConstr (UnQual (HsIdent n)) updates'
   where
    updates' = updates ++ [ HsFieldUpdate (UnQual (HsIdent "components")) (HsList []),
                            HsFieldUpdate (UnQual (HsIdent "buildEntries")) (HsList []),
                            HsFieldUpdate (UnQual (HsIdent "preProcessFiles")) (HsList []) ]

  initializeField' x = x



initializeField :: String -> String -> String -> HsModule -> HsModule
initializeField dataName fieldName value= everywhere (mkT initializeField')
 where
  initializeField' :: HsExp -> HsExp
  initializeField' (HsRecConstr (UnQual (HsIdent n)) updates) | n == dataName && value /= " " =
                    HsRecConstr (UnQual (HsIdent n)) updates'
   where
    updates' = updates ++ [ HsFieldUpdate
                              (UnQual (HsIdent fieldName))
                              (HsVar (UnQual (HsIdent value))) ]
  initializeField' x = x

--
-- This is a very specific (restricted) kind of constructor addition.
--
addConstructor :: String -> String -> String -> HsModule -> HsModule
addConstructor dataName typeName strUndefined
               (HsModule _ m exportSpec importDecls decls) = 
                HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1,decl,decls2) = findDataDecl dataName strUndefined decls
  componentType = HsUnBangedTy (HsTyCon (UnQual (HsIdent typeName)))
  decl' = case decl of
            (HsDataDecl _ [] n [] conDecls []) ->
             let conDecls' = conDecls ++ [HsConDecl noSrcLoc (HsIdent typeName) [componentType]] in
              HsDataDecl noSrcLoc [] n [] conDecls' []
            _ -> error ("Datatype " ++ dataName ++ " not suitable.")


--
-- Similar to addConstructor, but includes a new constructor without arguments. Used in the data type ExportModel 
--
addConstructorWithoutArgs :: String -> String -> String -> HsModule -> HsModule
addConstructorWithoutArgs dataName typeName strUndefined
               (HsModule _ m exportSpec importDecls decls) = 
                HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1,decl,decls2) = findDataDecl dataName strUndefined decls
  decl' = case decl of
            (HsDataDecl _ [] n [] conDecls []) ->
             let conDecls' = conDecls ++ [HsConDecl noSrcLoc (HsIdent typeName) []] in
              HsDataDecl noSrcLoc [] n [] conDecls' []
            _ -> error ("Datatype " ++ dataName ++ " not suitable.")


--
-- Please note that this operation makes rich assumptions.
--
addUpdateCase :: String    -- Function to transform
              -> String    -- Function to invoke in new case
              -> String    -- Constructor for 1st arg case
              -> [String]  -- Functions for args other than 1st and last
              -> String    -- Record selector for last argument
              -> HsModule  -- Module to transform
              -> HsModule
addUpdateCase funName funName' con argFuns sel
              (HsModule _ m exportSpec importDecls decls) = 
               HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1, HsFunBind cases, decls2) = findFunBind funName decls
  decl' = HsFunBind (cases ++ [HsMatch noSrcLoc (HsIdent funName) (pat1:vpats) rhs []])
  var1 = HsIdent "x0"
  pat1 = HsPApp (UnQual (HsIdent con)) [HsPVar var1]
  argFuns' = map (HsVar . UnQual . HsIdent) (argFuns ++ [sel])
  vars = map (HsIdent . (++) "x" . show) [1..length argFuns']
  vexps = map (HsVar . UnQual) vars
  vpats = map HsPVar vars 
  rhs = HsUnGuardedRhs (update (foldl apply fun' (zip vexps argFuns')))
  fun' = HsApp (HsVar (UnQual (HsIdent funName'))) (HsVar (UnQual var1)) 
  apply e (v,f) = HsApp e (HsParen (HsApp f v))
  update r = HsRecUpdate (last vexps) [HsFieldUpdate (UnQual (HsIdent sel)) r]


--
-- TODO: This is too specific variant of existing functionality.
-- Please note that this operation makes rich assumptions.
--
addCase :: String -> String -> String -> HsModule -> HsModule
addCase funName funName' con 
              (HsModule _ m exportSpec importDecls decls) = 
               HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1, HsFunBind cases, decls2) = findFunBind funName decls
  decl' = HsFunBind (cases ++ [HsMatch noSrcLoc (HsIdent funName) (pat1:vpats) rhs []])
  var1 = HsIdent "x0"
  pat1 = HsPApp (UnQual (HsIdent con)) [HsPVar var1]
  var1s = map (HsIdent . (++) "x" . show) [1..2]
  vpats = map HsPVar var1s
  vars = map ((++) " x" . show) [0..2]  
  rhs = HsUnGuardedRhs (HsApp (HsVar (UnQual (HsIdent funName'))) (HsVar (UnQual (HsIdent (concat vars)))))
  
--
-- TODO: This is too specific variant of existing functionality.
-- This operation is used to extend export function.
--
addCase2 :: String -> String -> String -> String  -> String -> HsModule -> HsModule
addCase2 funName funName' con extFile sel
              (HsModule _ m exportSpec importDecls decls) = 
               HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1, HsFunBind cases, decls2) = findFunBind funName decls
  decl' = HsFunBind (cases ++ [HsMatch noSrcLoc (HsIdent funName) (pat1:vpats) rhs []])
  pat1 = HsPApp (UnQual (HsIdent con)) []
  vars = map (HsIdent . (++) "x" . show) [1,2]
  vpats = map HsPVar vars 
  rhs = HsUnGuardedRhs (HsApp (HsApp (HsVar (UnQual (HsIdent funName'))) 
         (HsParen (HsInfixApp (HsVar (UnQual (HsIdent "x1"))) (HsQVarOp (UnQual (HsSymbol "++"))) (HsLit (HsString extFile))))) 
         (HsParen (HsApp (HsVar (UnQual (HsIdent sel))) (HsVar (UnQual (HsIdent "x2"))))))


--
-- TODO: This is too specific variant of existing functionality.
-- Please note that this operation makes rich assumptions. Add cases in format:
-- xml2Transformation ::String -> [String] -> ParserResult TransformationModel
-- xml2Transformation "selectScenarios" ids = Success (UseCaseTransformation (SelectScenarios ids))
--
addCase3 :: String -> String -> String -> String -> String -> String -> String -> HsModule -> HsModule
addCase3 funName typeTransf stTran dtTran peTran pDtTran condFunc
              (HsModule _ m exportSpec importDecls decls) = 
               HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
 where
  (decls1, HsFunBind cases, decls2) = findFunBind funName decls
  decl' = HsFunBind (cases ++ [HsMatch noSrcLoc (HsIdent funName) pat1 rhs []])
  pat1 = [HsPLit (HsString stTran), HsPVar (HsIdent peTran)]
  rhs = case condFunc of
	     "Success" -> HsUnGuardedRhs (HsApp (HsCon (UnQual (HsIdent condFunc))) (HsParen (HsApp (HsCon (UnQual (HsIdent typeTransf))) 
                       (HsParen (HsApp (HsCon (UnQual (HsIdent dtTran))) (HsVar (UnQual (HsIdent pDtTran))))))))
             otherwise -> HsUnGuardedRhs (HsApp (HsCon (UnQual (HsIdent condFunc))) (HsLit (HsString ("Invalid number of arguments to the transformation " ++ stTran))))
                       
-- 
-- add a new element in a list. Used to lists "lstExport" and "lstComandsMain" 
--
addListElem :: String -> String -> HsModule -> HsModule
addListElem dataName fieldName 
         (HsModule _ m exportSpec importDecls decls) = 
          HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
  where
  (decls1,decl,decls2) = findData dataName decls
  decl' = case decl of
            (HsPatBind _ n (HsUnGuardedRhs (HsList lst)) decls3) ->
	      let rhs' = (HsUnGuardedRhs (HsList (lst ++ [HsCon (UnQual (HsIdent fieldName))]))) in 
	          HsPatBind noSrcLoc n rhs' decls3
--             _ -> error ("Datatype " ++ dataName ++ " not suitable.")


-- Below we present three functions created to insert statements in the function "main" of the Hephaestus product.
-- They are the type of HsStmt instructins: HsLetStmt, HsGenerator and HsQualifier
-- They are used to insert statements about findPropertyValue, Parsers and Exports of assets 

--
-- addInstructionLet "main" "findPropertyValue" "target-dir" "u" "usecase-model"
--
addLetInstruction:: String -> String -> String -> String ->  String -> HsModule -> HsModule
addLetInstruction nameFunc p1 p2 name1 name2 
           (HsModule _ m exportSpec importDecls decls) = 
            HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
  where
  (decls1,decl,decls2) = findData nameFunc decls
  decl' = case decl of
	       (HsPatBind _ n (HsUnGuardedRhs (HsDo lstStmt)) lstdecl) -> 
	          if name2 /= " "
	             then 
	               let {(lstStmt1, stmt, lstStmt2) = findStmtLet p1 lstStmt ;
		    stmt'= [stmt] ++ [HsLetStmt [HsPatBind noSrcLoc (HsPVar (HsIdent name1)) (HsUnGuardedRhs (HsApp (HsVar (UnQual (HsIdent "fromJust"))) (HsParen (HsApp (HsApp (HsVar (UnQual (HsIdent p2))) (HsLit (HsString name2))) (HsVar (UnQual (HsIdent "ps"))))))) []]] } in 
		    (HsPatBind noSrcLoc n (HsUnGuardedRhs (HsDo (lstStmt1++stmt'++lstStmt2))) lstdecl )
		     else
		       (HsPatBind noSrcLoc n (HsUnGuardedRhs (HsDo lstStmt)) lstdecl)

--
-- let product = build fm fc cm spl
--
addLetInstruction':: String -> String -> HsModule -> HsModule
addLetInstruction' nameFunc varStmt 
           (HsModule _ m exportSpec importDecls decls) = 
            HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
  where
  (decls1,decl,decls2) = findData nameFunc decls
  decl' = case decl of
	       (HsPatBind _ n (HsUnGuardedRhs (HsDo lstStmt)) lstdecl) -> 
	          let {(lstStmt1, stmt, lstStmt2) = findStmtLet varStmt lstStmt ;
		    stmt'= [HsLetStmt  [HsPatBind noSrcLoc (HsPVar (HsIdent varStmt)) (HsUnGuardedRhs (HsApp (HsApp (HsApp (HsApp (HsVar (UnQual (HsIdent "build"))) (HsVar (UnQual (HsIdent "fm")))) (HsVar (UnQual (HsIdent "fc")))) (HsVar (UnQual (HsIdent "cm")))) (HsVar (UnQual (HsIdent "spl"))))) []]] } in 
		             (HsPatBind noSrcLoc n (HsUnGuardedRhs (HsDo (lstStmt1++stmt'++lstStmt2))) lstdecl )


--	        
-- search: imp <- parseInstanceModel (ns fcSchema) (snd i) 
-- insert: ucp <- parseUseCaseFile (ns ucSchema) (snd u) , for example
-- addInstructionGenerator "main" "parseInstanceModel" "ucp" parseUseCaseFile" "ucSchema" "u"
--
addGeneratorInstruction:: String -> String -> String -> String -> String -> HsModule -> HsModule
addGeneratorInstruction nameFunc fParseFind varParseNew fParseNew paramParseNew  
           (HsModule _ m exportSpec importDecls decls) = 
            HsModule noSrcLoc m exportSpec importDecls (decls1 ++ [decl'] ++ decls2)
  where
  (decls1,decl,decls2) = findData nameFunc decls
  decl' = case decl of
	       (HsPatBind _ n (HsUnGuardedRhs (HsDo lstStmt)) lstdecl) -> 
	          if fParseNew /= " "
	             then
	               let {(lstStmt1, stmt, lstStmt2) = findStmtParse fParseFind lstStmt ;
		             stmt'=  [stmt] ++ [HsGenerator noSrcLoc (HsPVar (HsIdent ("(Core.Success "++varParseNew++")"))) 
		                         (HsApp (HsVar (UnQual (HsIdent fParseNew))) (HsVar (UnQual (HsIdent paramParseNew)))) ] 
		       } in (HsPatBind noSrcLoc n (HsUnGuardedRhs (HsDo (lstStmt1++stmt'++lstStmt2))) lstdecl )
		     else
		       (HsPatBind noSrcLoc n (HsUnGuardedRhs (HsDo lstStmt)) lstdecl)
	     

--
-- remove, for example, the function main() of the Hephaestus instance, because its function main() is located in module IO.hs, i.e., builHpl function.
--
removeFunction:: String -> String -> HsModule -> HsModule
removeFunction nameFunc flag (HsModule _ m exportSpec importDecls decls) = HsModule noSrcLoc m exportSpec importDecls (decls1 ++ decls2)
  where
  (decls1,decl,decls2) = if flag == "funcBody" 
			    then 
			      findData nameFunc decls
			    else
			      findFuncIO nameFunc decls
	
-- ----------------------------------------------------------
-- Utilities for the transformations
-- ----------------------------------------------------------
findDataDecl :: String -> String -> [HsDecl] -> ([HsDecl], HsDecl, [HsDecl])
findDataDecl n strUndefined decls = findDataDecl' [] decls 
 where
  findDataDecl' _ [] = error ("Datatype " ++ n ++ " not found.")
  findDataDecl' decls1 (decl@(HsDataDecl p1 p2 n' p3 ((HsConDecl _ d' _):xd) p5):decls2)
      = if HsIdent n == n'
        then 
          if HsIdent strUndefined == d'
	     then (decls1, (HsDataDecl p1 p2 n' p3 xd p5), decls2)
	     else (decls1,decl,decls2)
        else findDataDecl' (decls1 ++ [decl]) decls2
  findDataDecl' decls1 (decl@(HsDataDecl _ _ n' _ _ _):decls2)
    = if HsIdent n == n'
        then (decls1,decl,decls2)
        else findDataDecl' (decls1 ++ [decl]) decls2
  findDataDecl' decls1 (decl:decls2)
    = findDataDecl' (decls1 ++ [decl]) decls2
    
  
findFunBind :: String -> [HsDecl] -> ([HsDecl], HsDecl, [HsDecl])
findFunBind n decls = findFunBind' [] decls 
 where
  findFunBind' _ [] = error ("Function " ++ n ++ " not found.")
  findFunBind' decls1 (decl@(HsFunBind ((HsMatch _ n' _ d' _):ms)):decls2)
    = if HsIdent n == n'
        then 
          if HsUnGuardedRhs (HsVar (UnQual (HsIdent "undefined"))) == d'
	     then (decls1,(HsFunBind (ms)),decls2)
	     else (decls1,decl,decls2)
        else findFunBind' (decls1 ++ [decl]) decls2
  findFunBind' decls1 (decl:decls2)
    = findFunBind' (decls1 ++ [decl]) decls2
  

-- HsPatBind noSrcLoc (HsPVar (HsIdent dataName)) rhs' [HsDecl]
findData :: String -> [HsDecl] -> ([HsDecl], HsDecl, [HsDecl])
findData n decls = findData' [] decls 
 where
  findData' _ [] = error ("Data " ++ n ++ " not found.")
  findData' decls1 (decl@(HsPatBind _ n' _ _ ):decls2)
    = if (HsPVar (HsIdent n)) == n'
        then (decls1,decl,decls2)
        else findData' (decls1 ++ [decl]) decls2
  findData' decls1 (decl:decls2)
    = findData' (decls1 ++ [decl]) decls2

    
findStmtLet :: String -> [HsStmt] -> ([HsStmt], HsStmt, [HsStmt])
findStmtLet varStmt stmts = find' [] stmts 
 where
  find' _ [] = error ("Command Let " ++ varStmt ++ " not found.")
  find' stmts1 (stmt@(HsLetStmt [HsPatBind _ var' _ _ ]):stmts2)
    = if (HsPVar (HsIdent varStmt)) == var'
        then (stmts1,stmt, stmts2)
        else find' (stmts1 ++ [stmt]) stmts2
  find' stmts1 (stmt:stmts2)
    = find' (stmts1 ++ [stmt]) stmts2    
    

-- findStmt to find the sentences: 
-- let t = fromJust (findPropertyValue "target-dir" ps)
-- imp <- parseInstanceModel (ns fcSchema) (snd i)  
findStmtParse :: String -> [HsStmt] -> ([HsStmt], HsStmt, [HsStmt])
findStmtParse parmStmt stmts = find' [] stmts 
 where
  find' _ [] = error ("Command " ++ parmStmt ++ " not found.")
  find' stmts1 (stmt@(HsGenerator _ _ (HsApp (HsApp p1' _ ) _ )):stmts2)
    = if (HsVar (UnQual (HsIdent parmStmt))) == p1'
        then (stmts1,stmt,stmts2)
        else find' (stmts1 ++ [stmt]) stmts2
  find' stmts1 (stmt:stmts2)
    = find' (stmts1 ++ [stmt]) stmts2  

-- find the declaration of a function ::IO() to remove into Hephaestus.hs instance
findFuncIO :: String -> [HsDecl] -> ([HsDecl], HsDecl, [HsDecl])
findFuncIO n decls = findFuncIO' [] decls 
 where
  findFuncIO' _ [] = error ("function " ++ n ++ ":: IO() not found.")
  findFuncIO' decls1 (decl@(HsTypeSig _ n' _ ):decls2)
    = if [HsIdent n] == n'
        then (decls1,decl,decls2)
        else findFuncIO' (decls1 ++ [decl]) decls2
  findFuncIO' decls1 (decl:decls2)
    = findFuncIO' (decls1 ++ [decl]) decls2
  

noSrcLoc :: SrcLoc
noSrcLoc = undefined

undefinedRhs :: HsRhs
undefinedRhs = HsUnGuardedRhs (HsVar (UnQual (HsIdent "undefined")))
