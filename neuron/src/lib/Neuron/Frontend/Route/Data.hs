{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Neuron.Frontend.Route.Data where

import Neuron.Cache.Type (NeuronCache (..))
import qualified Neuron.Config.Type as Config
import qualified Neuron.Frontend.Impulse as Impulse
import Neuron.Frontend.Manifest (Manifest)
import Neuron.Frontend.Route
  ( HeadHtml,
    Impulse,
    SiteData (SiteData),
    ZettelData (ZettelData),
  )
import qualified Neuron.Frontend.Theme as Theme
import Neuron.Zettelkasten.Connection (Connection (Folgezettel))
import qualified Neuron.Zettelkasten.Graph as G
import Neuron.Zettelkasten.ID (indexZid)
import Neuron.Zettelkasten.Query.Eval
  ( buildQueryUrlCache,
  )
import Neuron.Zettelkasten.Zettel
  ( ZettelC,
    ZettelT (zettelContent),
    sansContent,
  )
import Relude
import qualified Text.Pandoc.Util as P

mkZettelData :: NeuronCache -> ZettelC -> ZettelData
mkZettelData NeuronCache {..} zC = do
  let z = sansContent zC
      urls = either (const []) (P.getLinks . zettelContent) zC
      qurlcache = buildQueryUrlCache (G.getZettels _neuronCache_graph) urls
      upTree = G.backlinkForest Folgezettel z _neuronCache_graph
      backlinks = G.backlinks isJust z _neuronCache_graph
  ZettelData zC qurlcache upTree backlinks _neuronCache_graph

mkImpulseData :: NeuronCache -> Impulse
mkImpulseData NeuronCache {..} =
  Impulse.buildImpulse _neuronCache_graph _neuronCache_errors

mkSiteData :: NeuronCache -> HeadHtml -> Manifest -> SiteData
mkSiteData NeuronCache {..} headHtml manifest =
  let theme = Theme.mkTheme $ Config.theme _neuronCache_config
      siteTitle = Config.siteTitle _neuronCache_config
      siteAuthor = Config.author _neuronCache_config
      baseUrl = join $ Config.getSiteBaseUrl _neuronCache_config
      indexZettel = G.getZettel indexZid _neuronCache_graph
      editUrl = Config.editUrl _neuronCache_config
   in SiteData theme siteTitle siteAuthor baseUrl editUrl headHtml manifest _neuronCache_neuronVersion indexZettel
