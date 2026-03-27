import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { phone, otp } = await req.json()

        if (!phone || !otp) {
            return new Response(
                JSON.stringify({ error: 'Phone number and OTP are required' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        if (otp.length !== 6 || !/^\d+$/.test(otp)) {
            return new Response(
                JSON.stringify({ error: 'OTP must be 6 digits' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Find matching OTP
        const { data: otpRecords, error: fetchError } = await supabase
            .from('phone_otps')
            .select('*')
            .eq('phone_number', phone)
            .eq('otp_code', otp)
            .eq('verified', false)
            .gt('expires_at', new Date().toISOString())
            .order('created_at', { ascending: false })

        if (fetchError) {
            console.error('Error fetching OTP:', fetchError)
            throw new Error('Failed to verify OTP')
        }

        if (!otpRecords || otpRecords.length === 0) {
            console.log(`❌ Invalid OTP attempt for ${phone}`)

            // Increment attempts for any unexpired OTPs
            await supabase
                .from('phone_otps')
                .update({
                    attempts: supabase.raw('attempts + 1'),
                    updated_at: new Date().toISOString()
                })
                .eq('phone_number', phone)
                .eq('verified', false)
                .gt('expires_at', new Date().toISOString())

            return new Response(
                JSON.stringify({ error: 'Invalid or expired OTP' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const otpRecord = otpRecords[0]

        // Check attempt limit
        if (otpRecord.attempts >= 3) {
            console.log(`❌ Too many attempts for ${phone}`)
            return new Response(
                JSON.stringify({ error: 'Too many wrong attempts. Please request a new OTP.' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Mark as verified
        await supabase
            .from('phone_otps')
            .update({
                verified: true,
                updated_at: new Date().toISOString()
            })
            .eq('id', otpRecord.id)

        console.log(`✅ OTP verified for ${phone}`)

        // Get or create user
        // First, try to find existing user by phone
        const { data: existingUsers } = await supabase.auth.admin.listUsers()
        const existingUser = existingUsers.users.find(
            u => u.phone === phone || u.user_metadata?.phone === phone
        )

        let userId: string
        let userEmail: string

        if (existingUser) {
            console.log(`Found existing user: ${existingUser.id}`)
            userId = existingUser.id
            userEmail = existingUser.email || `${phone.replace(/\+/g, '')}@phone.local`
        } else {
            // Create new user
            userEmail = `${phone.replace(/\+/g, '')}@phone.local`

            const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
                email: userEmail,
                phone: phone,
                email_confirm: true,
                phone_confirm: true,
                user_metadata: {
                    phone: phone,
                    phone_verified: true,
                    created_via: 'phone_otp'
                }
            })

            if (createError) {
                console.error('Error creating user:', createError)
                throw new Error('Failed to create user account')
            }

            console.log(`Created new user: ${newUser.user.id}`)
            userId = newUser.user.id
        }

        // Generate access token
        const { data: sessionData, error: tokenError } = await supabase.auth.admin.generateLink({
            type: 'magiclink',
            email: userEmail
        })

        if (tokenError) {
            console.error('Error generating token:', tokenError)
            throw new Error('Failed to generate auth token')
        }

        return new Response(
            JSON.stringify({
                success: true,
                user_id: userId,
                access_token: sessionData.properties.action_link.split('&token=')[1],
                phone: phone
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error in verify-otp:', error)
        return new Response(
            JSON.stringify({
                error: error.message || 'Internal server error'
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
