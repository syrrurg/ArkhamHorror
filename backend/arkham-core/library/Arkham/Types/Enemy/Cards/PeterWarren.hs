{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Enemy.Cards.PeterWarren
  ( PeterWarren(..)
  , peterWarren
  )
where

import Arkham.Import

import Arkham.Types.Action hiding (Ability)
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Helpers
import Arkham.Types.Enemy.Runner

newtype PeterWarren = PeterWarren Attrs
  deriving newtype (Show, ToJSON, FromJSON)

peterWarren :: EnemyId -> PeterWarren
peterWarren uuid =
  PeterWarren
    $ baseAttrs uuid "01139"
    $ (healthDamageL .~ 1)
    . (fightL .~ 2)
    . (healthL .~ Static 3)
    . (evadeL .~ 3)
    . (uniqueL .~ True)

instance HasModifiersFor env PeterWarren where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env PeterWarren where
  getActions iid NonFast (PeterWarren attrs@Attrs {..}) =
    withBaseActions iid NonFast attrs $ do
      spendableClueCount <- getSpendableClueCount [iid]
      locationId <- getId @LocationId iid
      canAffordActions <- getCanAffordCost
        iid
        (toSource attrs)
        (Just Parley)
        (ActionCost 1)
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility
              (toSource attrs)
              1
              (ActionAbility (Just Parley) (ActionCost 1))
            )
        | canAffordActions
          && spendableClueCount
          >= 2
          && locationId
          == enemyLocation
        ]
  getActions _ _ _ = pure []

instance (EnemyRunner env) => RunMessage env PeterWarren where
  runMessage msg e@(PeterWarren attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) eid (LocationWithTitle "Miskatonic University")
    UseCardAbility iid (EnemySource eid) _ 1 | eid == enemyId ->
      e <$ unshiftMessages
        [SpendClues 2 [iid], AddToVictory (EnemyTarget enemyId)]
    _ -> PeterWarren <$> runMessage msg attrs
