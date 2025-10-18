package settings

// Branding contains the branding settings of the app.
type Branding struct {
	Name                  string `json:"name"`
	DisableExternal       bool   `json:"disableExternal"`
	DisableUsedPercentage bool   `json:"disableUsedPercentage"`
	DisableUserProfile    bool   `json:"disableUserProfile"`
	DefaultLoginUser      string `json:"defaultLoginUser"`
	Files                 string `json:"files"`
	Theme                 string `json:"theme"`
	Color                 string `json:"color"`
}
