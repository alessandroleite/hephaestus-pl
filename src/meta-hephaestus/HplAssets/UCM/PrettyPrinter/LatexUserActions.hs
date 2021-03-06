-----------------------------------------------------------------------------
-- |
-- Module      :  UseCaseModel.PrettyPrinter.Latex
-- Copyright   :  (c) Rodrigo Bonifacio 2008, 2009
-- License     :  LGPL
--
-- Maintainer  :  rba2@cin.ufpe.br
-- Stability   :  provisional
-- Portability :  portable
--
-- A Latex pretty printer for our Use Case Model data type. Useful for 
-- generating ps or pdf files from a use case model. Note that, in this 
-- implementation, only the user actions are represented.
--
--
-----------------------------------------------------------------------------

module HplAssets.UCM.PrettyPrinter.LatexUserActions (ucmToLatexUserActions) where 

import Text.PrettyPrint.HughesPJ

import HplAssets.UCM.Types

exportUcmToLatexUserActions:: FilePath -> UseCaseModel -> IO()
exportUcmToLatexUserActions f ucm = 
 bracket (openFile f WriteMode)
         hClose
         (\h -> hPutStr h (show (ucmToLatexUserActions ucm)))
         

ucmToLatexUserActions :: UseCaseModel -> Doc
ucmToLatexUserActions (UCM name ucs as) = vcat [ beginDocument name
                                    , ucsToLatex ucs
                                    , endDocument
                                    ]

beginDocument :: String -> Doc
beginDocument name =
 vcat [ text "%This Latex file is machine-generated by the Hephaestus\n"
      , text "\\documentclass[a4paper,11pt]{article}"
      , text "\\usepackage[brazil]{babel}"
      , text "\\usepackage[latin1]{inputenc}"      
      , text "\\newcommand{\\bl}{\\\\ \\hline}"
      , text ("\\title{" ++ name ++ "}")
      , text "\\begin{document}" 
      , text "\\maketitle"
      ]



ucsToLatex :: [UseCase] -> Doc 
ucsToLatex [] = empty
ucsToLatex (x:xs) = vcat ((text "\\section*{Use cases}") : (map ucToLatex (x:xs)))
 where 
   ucToLatex  uc = vcat ([ text ("\\subsection*{Use case " ++ (ucId uc) ++ "}") 
                         , text ("\\begin{itemize}") 
                         , text ("\\item {\\bf Name: }" ++ (ucName uc) )
                         , text ("\\item {\\bf Description: }" ++ (ucDescription uc))
                         , text ("\\end{itemize}" )  
                         ] ++ (map scenarioToLatex (ucScenarios uc)))

scenarioToLatex :: Scenario -> Doc
scenarioToLatex (Scenario i d f s t) = vcat ([ text ("\\subsubsection*{Scenario " ++ i ++ "}")
                                             , text ("\\begin{tabular}{p{1in}p{4in}}")
                                             , text ("{\\bf Description:} & " ++ d ++ " \\\\")
                                             , text ("\\end{tabular}")
                                             , text (" ")
                                             ] ++ [(flowToLatex s)])

flowToLatex :: Flow -> Doc
flowToLatex [] = empty
flowToLatex (s:ss) = vcat (map stepToLatex (s:ss))       
                     

stepToLatex :: Step -> Doc
stepToLatex (Step i a s r an) = hcat [ text i
                                     , text " ) " 
                                     , text a
                                     ]

endDocument :: Doc
endDocument =  text "\\end{document}"