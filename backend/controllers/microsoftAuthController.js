// controllers/microsoftAuthController.js

const microsoftLogin = async (req, res) => {
    try {

        const user = req.microsoftUser;

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "Microsoft user not found"
            });
        }

        return res.status(200).json({
            success: true,
            message: `${user.name} managed to successfully login with the Microsoft account.`,
            user: {
                name: user.name,
                email: user.email,
                oid: user.oid,
                tenantId: user.tenantId
            }
        });

    } catch (error) {

        console.error(
            "Microsoft login controller error:",
            error
        );

        return res.status(500).json({
            success: false,
            message: "Unable to process Microsoft login",
            error: error.message
        });
    }
};

const getMicrosoftProfile = async (req, res) => {
    try {

        const user = req.microsoftUser;

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "User not authenticated"
            });
        }

        return res.status(200).json({
            success: true,
            profile: {
                name: user.name,
                email: user.email,
                oid: user.oid,
                tenantId: user.tenantId
            }
        });

    } catch (error) {

        console.error(
            "Get Microsoft profile error:",
            error
        );

        return res.status(500).json({
            success: false,
            message: "Unable to retrieve profile",
            error: error.message
        });
    }
};

module.exports = {
    microsoftLogin,
    getMicrosoftProfile
};
