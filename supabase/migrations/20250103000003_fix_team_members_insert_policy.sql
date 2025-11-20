-- Fix team_members INSERT policy to allow team owners to add members when approving join requests

DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;

CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );
