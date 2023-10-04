package model

// import "gorm.io/gorm"

type Consumer struct {
	Id                         string  `json:"id,omitempty"`
	Aadhar_number              int     `json:"aadhar,omitempty"`
	Addr1                      *string `json:"addr1"`
	Addr2                      string  `json:"addr2"`
	Circle_id                  string  `json:"circle_id"`
	Consumer_number            string  `json:"consumer_number"`
	Consumer_type              string  `json:"consumer_type"`
	Division_id                string  `json:"division_id"`
	Load                       int     `json:"load"`
	Meter_make                 string  `json:"meter_make"`
	Meter_number               string  `json:"meter_number"`
	Meter_status               string  `json:"meter_status"`
	Mobile                     int     `json:"mobile"`
	Name                       *string `json:"name" gorm:"not null"`
	Sub_division_id            string  `json:"sub_division_id"`
	Tariff                     string  `json:"tariff"`
	Supervisor_approval_status string  `json:"supervisor_approval_status"`
	Created_by                 string  `json:"created_by"`
}

type Circles struct {
	// gorm.Model
	Id        string `json:"id"`
	Circle    string
	Divisions []Divisions `gorm:"foreignKey:Circle_id;references:Id"`
}

type Divisions struct {
	// gorm.Model
	Id        string `json:"id"`
	Circle_id string `json:"circle_id"`
	Division  string
	// Circles       Circles         `gorm:"foreignKey:Circle_id"`
	Sub_divisions []Sub_divisions `gorm:"foreignKey:Division_id;references:Id"`
}

type Sub_divisions struct {
	ID           string `json:"id"`
	Division_id  string
	Sub_division string
	// Divisions []Division `gorm:"foreignKey:Circle_id;references:Id"`
	// Divisions []Division `gorm:"foreignKey:Division_id"`
}
