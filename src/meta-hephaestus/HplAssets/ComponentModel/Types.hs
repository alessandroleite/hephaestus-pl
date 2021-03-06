-----------------------------------------------------------------------------
-- |
-- Module      :  ComponentModel.Types
-- Copyright   :  (c) Rodrigo Bonifacio 2008, 2009
-- License     :  LGPL
--
-- Maintainer  :  rba2@cin.ufpe.br
-- Stability   :  provisional
-- Portability :  portable
--
-- A generic (and simple) component model in Haskell for product 
-- line development. Although simple, it can be used with the purpose 
-- of representing source code assets as file paths.
--
-----------------------------------------------------------------------------
module HplAssets.ComponentModel.Types
where 

import BasicTypes


data ComponentTransformation = SelectComponents [Id] 
			     | SelectAndMoveComponent Id String
	                     | CreateBuildEntries [String]
			     | PreProcessor [Path]
			     deriving (Show, Eq, Ord)

type ComponentModel = [ComponentMapping]
type Component = String 
type ComponentMapping = (Id, Component)




