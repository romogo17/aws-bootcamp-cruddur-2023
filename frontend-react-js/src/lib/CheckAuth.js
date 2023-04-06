import { Auth } from 'aws-amplify';

export async function getAccessToken() {
    try {
        const cognito_user_session = await Auth.currentSession()
        const access_token = cognito_user_session.accessToken.jwtToken
        localStorage.setItem("access_token", access_token)
        // console.log('getAccessToken(): access_token', access_token)
        return access_token
    } catch (err) {
        console.log(err)
    }
}

export async function checkAuth(setUser) {

    try {
        const cognito_user = await Auth.currentAuthenticatedUser({
            // Optional, by default is false. If set to true, this call will send a request to Cognito to get the latest user data
            bypassCache: false
        })
        // console.log('checkAuth(): cognito_user', cognito_user);
        setUser({
            display_name: cognito_user.attributes.name,
            handle: cognito_user.attributes.preferred_username
        })

        const cognito_user_session = await Auth.currentSession()
        // console.log('checkAuth(): cognito_user_session', cognito_user_session);
        localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
    } catch (err) {
        console.log(err)
    }
};

export default checkAuth;